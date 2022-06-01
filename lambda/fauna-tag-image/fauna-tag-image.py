import boto3
import json
import pymysql
from configparser import ConfigParser

config = ConfigParser()

s3_client = boto3.client("s3")
s3_app_bucket = 'fauna-images-REPLACE_ME_UUID'
s3_admin_bucket = 'fauna-admin-REPLACE_ME_UUID'

def tag_image(event, context):

    rds_config = s3_client.get_object(Bucket=s3_admin_bucket, Key='app_config.ini')
    config.read_string(rds_config['Body'].read().decode())
    
    db_endpoint = config.get('RDS','db_endpoint')
    db_user = config.get('RDS', 'db_user')
    db_password = config.get('RDS', 'db_password')
    db_name = config.get('RDS', 'db_name')

    try:
        conn = pymysql.connect(host=db_endpoint, user=db_user, passwd=db_password, db=db_name, connect_timeout=5)
    except pymysql.MySQLError as e:
        logger.error("ERROR: Unexpected error: Could not connect to MySQL instance.")
        logger.error(e)
        sys.exit()

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
        with conn.cursor() as cur:
            cur.execute('INSERT INTO Tags (PhotoID, Tags) VALUES (1' + tags + ')')
            conn.commit()
        return "Success"