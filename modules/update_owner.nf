// Makes current Synapse user owner of Storage Location
process UPDATE_OWNER {
  label 'aws'

  input:
  val user_id
  val s3_prefix

  output:
  val "ready"

  script:
  """
  ( \
     ( aws s3 cp ${s3_prefix}/owner.txt - 2>/dev/null || true ); \
      echo $user_id \
  ) \
  | sort -u \
  | aws s3 cp - ${s3_prefix}/owner.txt
  """

}
