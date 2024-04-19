// Create matching folder structure in Synapse upload location
process SYNAPSE_MIRROR {
  debug true
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'

  publishDir "${publish_dir}", mode: 'copy'
  

  input:
  path  objects
  val   s3_prefix
  val   parent_id
  val   publish_dir

  output:
  path  'parent_ids.csv'

  script:
  """
  synapse_mirror.py ${objects} ${s3_prefix} ${parent_id}
  """

}
