import boto3
import uuid

s3_client = boto3.client("s3")
S3_BUCKET= 'fauna-images-REPLACE_ME_UUID'

def register_account(event, context):
    requested_user_name = event['requested_user_name']

    if requested_user_name not None: # eventually... is unique
        uid = uuid.uuid4() 
        return "Thank you for registering, " + user_name + ". Your unique ID is: " + uid + ". Please keep this for future reference."
    else:
        return "User already registered. If you have forgotten your unique ID and/or username, please generate a new one."