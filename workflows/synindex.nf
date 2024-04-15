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
  bucket = matches[0][1]
  base_key = matches[0][2]
  base_key = base_key ?: '/'
  s3_prefix = "s3://${bucket}/${base_key}"  // Ensuring common format
}

if ( !params.parent_id ==~ 'syn[0-9]+' ) {
  exit 1, "Parameter 'params.parent_id' must be the Synapse ID of a folder (e.g., 'syn98765432')!\n"
}

publish_dir = "${s3_prefix}/synindex/under-${params.parent_id}/"

/*
========================================================================================
    IMPORT MODULES
========================================================================================
*/

include { GET_USER_ID } from '../modules/get_user_id.nf'
include { UPDATE_OWNER } from '../modules/update_owner.nf'
include { REGISTER_BUCKET } from '../modules/register_bucket.nf'
include { LIST_OBJECTS } from '../modules/list_objects.nf'

/*
========================================================================================
    WORKFLOW DEFINITION
========================================================================================
*/

process SYNAPSE_MIRROR {
  debug true
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'

  //does not work locally
  publishDir publish_dir, mode: 'copy'
  

  input:
  path  objects
  val   s3_prefix
  val   parent_id

  output:
  path  'parent_ids.csv'

  script:
  """
  synmirror.py ${objects} ${s3_prefix} ${parent_id}
  """

}

process SYNAPSE_INDEX {
  
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'

  input:
  tuple val(uri), file(object), val(parent_id)
  val   storage_id

  output:
  env file_info

  script:
  """
  file_info=\$(synindex.py ${storage_id} ${object} '${uri}' ${parent_id})
  """

}

workflow SYNINDEX {
  GET_USER_ID()
  GET_USER_ID.output.view()
  UPDATE_OWNER(GET_USER_ID.output, s3_prefix)
  UPDATE_OWNER.output.view()
  REGISTER_BUCKET(bucket, base_key, UPDATE_OWNER.output)
  REGISTER_BUCKET.output.view()
  LIST_OBJECTS(s3_prefix, bucket, params.filename_string)
  LIST_OBJECTS.output.view()
  SYNAPSE_MIRROR(LIST_OBJECTS.output, s3_prefix, params.parent_id)
  SYNAPSE_MIRROR.output.view()
  ch_parent_ids = SYNAPSE_MIRROR.output 
        .splitCsv(header:true) 
        .map { row -> tuple(row.object_uri, file(row.object_uri), row.folder_id) }
  ch_parent_ids.view()
  ch_file_ids = SYNAPSE_INDEX(ch_parent_ids, REGISTER_BUCKET.output)
  ch_file_ids
    .collectFile(name: "file_ids.csv", storeDir: publish_dir, newLine: true)
}








