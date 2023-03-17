import boto3
import re,sys
from botocore.exceptions import ClientError
from pprint import pprint

DEBUG = True

def get_all_secrets(s3_client):
  try:
    response = s3_client.list_secrets(MaxResults=100)
    return response
  except ClientError as e:
    raise Exception("boto3 client error in get_all_secrets: " + e.__str__())
  except Exception as e:
    raise Exception("Unexpected error in get_all_secrets: " + e.__str__())

def get_secret_string(s3_client,secret_name):
  try:
    get_secret_value_response = s3_client.get_secret_value(
      SecretId=secret_name
    )
  except ClientError as e:
    if e.response['Error']['Code'] == 'ResourceNotFoundException':
      print("The requested secret " + secret_name + " was not found")
    elif e.response['Error']['Code'] == 'InvalidRequestException':
      print("The request was invalid due to:", e)
    elif e.response['Error']['Code'] == 'InvalidParameterException':
      print("The request had invalid params:", e)
    elif e.response['Error']['Code'] == 'DecryptionFailure':
      print("The requested secret can't be decrypted using the provided KMS key:", e)
    elif e.response['Error']['Code'] == 'InternalServiceError':
      print("An error occurred on service side:", e)
  else:
      if 'SecretString' in get_secret_value_response:
        text_secret_data = get_secret_value_response['SecretString']
  DEBUG and print(f"secret string for {secret_name} is {text_secret_data}")
  return text_secret_data

def create_secret(s3_client,secret_name,secret_string,replicate):

  if DEBUG:
    return { "Name": secret_name }

  replica_regions = []
  if replicate is True:
    replica_regions = [
        {
            'Region': 'us-east-2',
        },
      ]

  response = s3_client.create_secret(
    Name=secret_name,
    SecretString=secret_string,
    AddReplicaRegions=replica_regions
  )
  return response

def main():
  if len(sys.argv) < 2:
    sys.exit(f"Usage: {sys.argv[0]} <source_stage> <destination_stage> [no_debug:int]")

  source_stage = sys.argv[1]
  dest_stage = sys.argv[2]
  DEBUG = len(sys.argv) > 2 and int(sys.argv[3]) > 0
  DEBUG and print(f"==== Copying secrets from {source_stage} to {dest_stage} ====")

  # Start session
  session = boto3.session.Session()
  s3_client = session.client(
    service_name='secretsmanager',
    region_name='us-east-1'
  )

  # Get all secrets
  a = get_all_secrets(s3_client)
  DEBUG and pprint(a)
  secret_names = list(b['Name'] for b in a['SecretList'])

  # Work on all the secrets
  for secret_name in secret_names:
    print(f"> working on {secret_name}")

    # Establish the new secret name
    new_name = re.sub(source_stage, dest_stage, secret_name)
    print(f">> secret {secret_name} will be copied to {new_name}")

    # Skip the ones that already exist
    pattern = re.compile(dest_stage)
    if pattern.search(secret_name) is not None:
      print(f"=== skipping '{secret_name}' because it contains the string '{dest_stage}'")
      continue

    if new_name in secret_names:
      print(f"--- skipping copying of '{secret_name}' because '{new_name}' already exists")
      continue

    # Get the secret string
    secret_string = get_secret_string(s3_client,secret_name)
    DEBUG and print(secret_string)

    # Create new secret
    resp = create_secret(s3_client,new_name,secret_string,True)
    print(f"+++ {resp['Name']} successfully created")

main() 
