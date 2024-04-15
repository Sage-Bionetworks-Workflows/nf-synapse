// Registers external S3 bucket as a Storage Location in Synapse
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
