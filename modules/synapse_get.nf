// Download files from Synapse
process SYNAPSE_GET {

  publishDir "${outdir}/${syn_id}/", mode: 'copy'

  secret 'SYNAPSE_AUTH_TOKEN'

  input:
  tuple val(syn_uri), val(syn_id)
  val outdir

  output:
  tuple val(syn_uri), val(syn_id), path("*")

  script:
  """
  synapse get ${syn_id}
  """
}
