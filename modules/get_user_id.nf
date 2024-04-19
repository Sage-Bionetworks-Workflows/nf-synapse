// Get Synapse user ID number
process GET_USER_ID {
  
  label 'synapse'

  cache false

  secret 'SYNAPSE_AUTH_TOKEN'

  output:
  env user_id

  script:
  """
  user_id=\$(get_user_id.py)
  """

}
