// Ensure DSL2
nextflow.enable.dsl = 2

/*
========================================================================================
    SETUP PARAMS
========================================================================================
*/
params.filename_string = false

matches = ( params.s3_prefix =~ '^s3://([^/]+)(?:/+([^/]+(?:/+[^/]+)*)/*)?$' ).findAll()

if ( matches.size() == 0 ) {
  exit 1, "Parameter 'params.s3_prefix' must be an S3 URI (e.g., 's3://bucket-name/some/prefix/')!\n"
} else {
  bucket = matches[0][1]
  base_key = matches[0][2]
  base_key = base_key ?: '/'
  s3_prefix = "s3://${bucket}/${base_key}"
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
include { SYNAPSE_MIRROR } from '../modules/synapse_mirror.nf'
include { SYNAPSE_INDEX } from '../modules/synapse_index.nf'

/*
========================================================================================
    WORKFLOW DEFINITION
========================================================================================
*/

workflow SYNINDEX {
  GET_USER_ID()
  UPDATE_OWNER(GET_USER_ID.output, s3_prefix)
  REGISTER_BUCKET(bucket, base_key, UPDATE_OWNER.output)
  LIST_OBJECTS(s3_prefix, bucket, params.filename_string)
  SYNAPSE_MIRROR(LIST_OBJECTS.output, s3_prefix, params.parent_id, publish_dir)
  ch_parent_ids = SYNAPSE_MIRROR.output 
        .splitCsv(header:true) 
        .map { row -> tuple(row.object_uri, file(row.object_uri), row.folder_id) }
  ch_file_ids = SYNAPSE_INDEX(ch_parent_ids, REGISTER_BUCKET.output)
  ch_file_ids
    .collectFile(name: "output.csv", storeDir: publish_dir, newLine: true)
}
