// Download files from Synapse
process SYNAPSE_GET {
  label 'synapse'
  label 'download'

  tag "$syn_id"

  secret 'SYNAPSE_AUTH_TOKEN'

  input:
  tuple val(syn_uri), val(syn_id)

  output:
  tuple val(syn_uri), val(syn_id), path("*")
  
  when:
  params.synapse_uris.size() > 0

  script:
  """
  synapse get ${syn_id}
  """
}
