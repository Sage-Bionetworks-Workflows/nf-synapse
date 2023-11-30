// Update Synapse URIs in input file with staged locations
process UPDATE_INPUT {

  publishDir "${input_file.scheme}://${input_file.parent}/synstage/",  mode: 'copy'
  publishDir "${outdir}/${run_name}/",          mode: 'copy'

  input:
  path input_file
  val exprs
  tuple val(a), val(b), val(c)

  output:
  path "${input_file.name}"

  script:
  """
  sed -E ${exprs} ${input_file} > ${input_file.name}
  """

}
