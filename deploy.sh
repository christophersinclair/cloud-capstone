#!/bin/bash


#### AWS CLI ####
aws configure set region us-east-1
aws configure set aws_access_key_id $(grep aws_access_key_id cli.ini | awk -F'=' '{ print $2 }')
aws configure set aws_secret_access_key $(grep aws_secret_access_key cli.ini | awk -F'=' '{ print $2 }')

cd terraform
terraform init
terraform plan -out execution_plan.tfplan

terraform apply "execution_plan.tfplan"