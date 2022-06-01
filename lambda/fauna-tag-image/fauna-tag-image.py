import boto3
import json
import pymysql

s3_client = boto3.client("s3")
s3_bucket = 'fauna-images-REPLACE_ME_UUID'

def tag_image(event, context):
    user_uuid = event['uuid']
    image = event['image_name']
    tags = event['tags']


    # See if object exists in S3
    object_key = s3_dir+'/'+image
    try:
        file_content = s3_client.get_object(Bucket=S3_BUCKET, Key=object_key)["Body"].read()
    except:
        return "Image to tag not found."
    else:
        # Store the image tag in the database
        return "Success"