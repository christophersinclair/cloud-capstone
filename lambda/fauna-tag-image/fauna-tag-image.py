import boto3

s3_client = boto3.client("s3")
S3_BUCKET= 'fauna-images-REPLACE_ME_UUID'

def tag_image(event, context):
    return "Hello, mlglc!"