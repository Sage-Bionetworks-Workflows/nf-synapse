// Create matching folder structure in Synapse upload location
process SYNAPSE_MIRROR {
  debug true
  label 'synapse'

  secret 'SYNAPSE_AUTH_TOKEN'

  input:
  path  objects
  val   s3_prefix
  val   parent_id

  // Internal hand-off to SYNAPSE_INDEX only; the published mapping of this
  // workflow is `output.csv`, which carries these columns plus the Synapse IDs.
  output:
  path  'parent_ids.csv'

  script:
  """
  synapse_mirror.py ${objects} ${s3_prefix} ${parent_id}
  """

}
