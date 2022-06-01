import boto3
import json
import pymysql

s3_client = boto3.client("s3")
s3_app_bucket = 'fauna-images-REPLACE_ME_UUID'
s3_admin_bucket = 'fauna-admin-REPLACE_ME_UUID'

def tag_image(event, context):

    rds_config = s3_client.get_object(Bucket=s3_admin_bucket, Key='rds_config.ini')["Body"].read()
    print(rds_config)

    user_uuid = event['uuid']
    image = event['image_name']
    tags = event['tags']

    s3_dir = user_uuid + '/' + image

    # See if image to tag exists in S3
    object_key = s3_dir
    try:
        file_content = s3_client.get_object(Bucket=s3_app_bucket, Key=object_key)["Body"].read()
    except:
        return "Image to tag not found."
    else:
        # Store the image tag in the database
        return "Success"