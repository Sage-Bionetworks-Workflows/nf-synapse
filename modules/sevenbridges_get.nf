// Download files from SevenBridges
process SEVENBRIDGES_GET {

  container "quay.io/biocontainers/sevenbridges-python:2.9.1--pyhdfd78af_0"

  publishDir "${outdir}/${sbg_id}/", mode: 'copy'

  secret 'SB_API_ENDPOINT'
  secret 'SB_AUTH_TOKEN'

  input:
  tuple val(sbg_uri), val(sbg_id)
  val outdir

  output:
  tuple val(sbg_uri), val(sbg_id), path("*")

  script:
  """

  #!/usr/bin/env python3

  import sevenbridges as sbg

  api = sbg.Api()
  download_file = api.files.get('${sbg_id}')
  download_file.download(download_file.name)

  """

}
