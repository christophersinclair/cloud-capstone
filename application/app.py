from flask import Flask
import os
import boto3
import requests
import json

app = Flask(__name__)

@app.route('/get/tag')
def get_tag():
    return "Hello world!"

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=80)
