// Index external S3 files in Synapse
process SYNAPSE_INDEX {
  
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'

  input:
  tuple val(uri), file(object), val(parent_id)
  val   storage_id

  output:
  path 'file_info.csv'

  script:
  """
  synapse_index.py ${storage_id} ${object} '${uri}' ${parent_id}
  """

}
