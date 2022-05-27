#!/bin/bash

#### AWS CLI ####
aws configure set region us-east-1
aws configure set aws_access_key_id $(grep aws_access_key_id cli.ini | awk -F'=' '{ print $2 }')
aws configure set aws_secret_access_key $(grep aws_secret_access_key cli.ini | awk -F'=' '{ print $2 }')


#### Lambda ####
# Lambda code packaging
for x in $(ls lambda); do
    cd ${x} && zip ${x}.zip ${x}.py
done

# Update generic AWS Lambda with custom code
aws lambda update-function-code \
    --function-name fauna-tag-image-function \
    --zip-file fileb://lambda/fauna-tag-image/fauna-tag-image.zip