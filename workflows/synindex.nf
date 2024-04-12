#!/usr/bin/env nextflow

// Ensure DSL2
nextflow.enable.dsl = 2

/*
========================================================================================
    SETUP PARAMS
========================================================================================
*/

// Default values
params.s3_prefix = false
params.parent_id = false
params.synapse_config = false
params.filename_string = false

if ( !params.s3_prefix ) {
  exit 1, "Parameter 'params.s3_prefix' is required!\n"
}

if ( !params.parent_id ) {
  exit 1, "Parameter 'params.parent_id' is required!\n"
}

matches = ( params.s3_prefix =~ '^s3://([^/]+)(?:/+([^/]+(?:/+[^/]+)*)/*)?$' ).findAll()

if ( matches.size() == 0 ) {
  exit 1, "Parameter 'params.s3_prefix' must be an S3 URI (e.g., 's3://bucket-name/some/prefix/')!\n"
} else {
  bucket_name = matches[0][1]
  base_key = matches[0][2]
  base_key = base_key ?: '/'
  s3_prefix = "s3://${bucket_name}/${base_key}"  // Ensuring common format
}

if ( !params.parent_id ==~ 'syn[0-9]+' ) {
  exit 1, "Parameter 'params.parent_id' must be the Synapse ID of a folder (e.g., 'syn98765432')!\n"
}

publish_dir = "${s3_prefix}/synindex/under-${params.parent_id}/"


/*
========================================================================================
    WORKFLOW DEFINITION
========================================================================================
*/
process GET_USER_ID {
  
  label 'synapse'

  cache false

  secret 'SYNAPSE_AUTH_TOKEN'

  output:
  env user_id

  script:
  """
  user_id=\$(get_user_id.py)
  """

}

process UPDATE_OWNER {
  
  label 'aws'

  input:
  val user_id
  val s3_prefix

  output:
  val "ready"

  script:
  """
  ( \
     ( aws s3 cp ${s3_prefix}/owner.txt - 2>/dev/null || true ); \
      echo $user_id \
  ) \
  | sort -u \
  | aws s3 cp - ${s3_prefix}/owner.txt
  """

}

process REGISTER_BUCKET {
  
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'

  input:
  val   bucket
  val   base_key
  val   ready

  output:
  env storage_location_id

  script:
  """
  storage_location_id=\$(register_bucket.py ${bucket} ${base_key})
  """

}

process LIST_OBJECTS {

  label 'aws'

  input:
  val s3_prefix
  val bucket
  val filename_string
  
  output:
  path 'objects.txt'

  script:
  """
  aws s3 ls ${s3_prefix}/ --recursive \
  | grep -v -e '/\$' -e 'synindex/under-' -e 'owner.txt\$' \
    -e 'synapseConfig' -e 'synapse_config' \
  | awk '{\$1=\$2=\$3=""; print \$0}' \
  | sed 's|^   |s3://${bucket}/|' \
  ${filename_string ? "| grep '${filename_string}'" : ""} \
  > objects.txt
  """
  
}

process SYNAPSE_MIRROR {
  
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'

  publishDir publish_dir, mode: 'copy'

  input:
  path  objects
  val   s3_prefix
  val   parent_id

  output:
  path  'parent_ids.csv'

  script:
  config_cli_arg = params.synapse_config ? "--config ${syn_config}" : ""
  """
  synmirror.py ${objects} ${s3_prefix} ${parent_id} > parent_ids.csv
  """

}

workflow synindex {
  GET_USER_ID()
  UPDATE_OWNER(GET_USER_ID.output, s3_prefix)
  REGISTER_BUCKET(bucket, base_key, UPDATE_OWNER.output)
  LIST_OBJECTS(s3_prefix, bucket, params.filename_string)
  SYNAPSE_MIRROR(LIST_OBJECTS.output, s3_prefix, parent_id)
  // Parse list of object URIs and their Synapse parents
  ch_parent_ids_csv
    .text
    .splitCsv()
    .map { row -> [ row[0], file(row[0]), row[1] ] }
    .set { ch_parent_ids }
}





process SYNAPSE_INDEX {
  
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'


  input:
  tuple val(uri), file(object), val(parent_id)
  val   storage_id

  output:
  stdout ch_file_ids

  script:
  config_cli_arg = params.synapse_config ? "--config ${syn_config}" : ""
  """
  synindex.py \
  --storage_id ${storage_id} \
  --file ${object} \
  --uri '${uri}' \
  --parent_id ${parent_id} \
  ${config_cli_arg}
  """

}


ch_file_ids
  .collectFile(name: "file_ids.csv", storeDir: publish_dir, newLine: true)
