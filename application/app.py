from flask import Flask
from flask import send_file
from flask import request
import os
import boto3
import requests
import json
import io

app = Flask(__name__)


AWS_ACCESS_KEY_ID = 'REPLACE_ME_KEY_ID'
AWS_SECRET_ACCESS_KEY = 'REPLACE_ME_SECRET_KEY'

s3 = boto3.resource('s3', aws_access_key_id=AWS_ACCESS_KEY_ID, aws_secret_access_key=AWS_SECRET_ACCESS_KEY)
s3_client = boto3.client("s3")
s3_app_bucket = 'fauna-images-REPLACE_ME_UUID'


def check_exists(s3_object_key):
    try:
        s3_client.head_object(Bucket=s3_app_bucket, Key=s3_object_key)
        return True
    except:
        print("Image does not exist!")
        return False

@app.route('/image',methods=['GET','POST'])
def get_tag():
    user_uuid = request.args.get('uuid')
    image_name = request.args.get('image')

    s3_object_key = user_uuid +  '/' + image_name

    object_exists = check_exists(s3_object_key)

    if not object_exists:
        return "Image does not exist!"

    try:
        a_file = io.BytesIO()
        s3_object = s3.Object(s3_app_bucket, s3_object_key)
        s3_object.download_fileobj(a_file)

        a_file.seek(0)
        
        return send_file(a_file, mimetype=s3_object.content_type)
    except:
        return "Image exists but could not load from bucket!"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=80)
