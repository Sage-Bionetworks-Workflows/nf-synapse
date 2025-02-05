// Download files from Seven Bridges
process SEVENBRIDGES_GET {
  label 'sevenbridges'
  label 'download'

  secret 'SB_API_ENDPOINT'
  secret 'SB_AUTH_TOKEN'

  input:
  tuple val(sbg_uri), val(sbg_id)

  output:
  tuple val(sbg_uri), val(sbg_id), path("*")

  when:
  params.sbg_uris.size() > 0

  script:
  """
  sevenbridges_get.py '${sbg_id}'
  """

}
