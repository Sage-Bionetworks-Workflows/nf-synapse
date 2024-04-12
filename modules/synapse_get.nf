// Download files from Synapse
process SYNAPSE_GET {
  label 'synapse'

  publishDir "${Utils.get_publish_dir(params, syn_id)}", mode: 'copy'

  secret 'SYNAPSE_AUTH_TOKEN'

  input:
  tuple val(syn_uri), val(syn_id)

  when:
  params.synapse_uris.size() > 0

  output:
  tuple val(syn_uri), val(syn_id), path("*")

  script:
  """
  synapse get ${syn_id}
  """
}
