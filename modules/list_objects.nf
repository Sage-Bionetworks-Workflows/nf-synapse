// Gets S3 uris for all files in an S3 bucket
process LIST_OBJECTS {

  label 'aws'

  input:
  val s3_prefix
  val bucket
  val filename_string
  
  output:
  path 'objects.txt'

  script:
  """
  aws s3 ls ${s3_prefix}/ --recursive \
  | grep -v -e '/\$' -e 'synindex/under-' -e 'owner.txt\$' \
  | awk '{\$1=\$2=\$3=""; print \$0}' \
  | sed 's|^   |s3://${bucket}/|' \
  ${filename_string ? "| grep '${filename_string}'" : ""} \
  > objects.txt
  """
  
}
