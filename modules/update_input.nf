// Update Synapse URIs in input file with staged locations
process UPDATE_INPUT {

  label 'aws'
  
  publishDir "${input_file.scheme}:///${params.input_parent_dir}/synstage/",  mode: 'copy'
  publishDir "${params.outdir_clean}/${run_name}/",          mode: 'copy'

  stageInMode 'copy'

  input:
  file input_file
  val exprs
  val run_name

  output:
  path "${input_file}"

  script:
  """
  cp ${input_file} input.txt
  sed -E ${exprs} input.txt > ${input_file}
  """
} 
