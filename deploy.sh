#!/bin/bash


#### AWS CLI ####
aws configure set region $(grep aws_region cli.ini | awk -F'=' '{ print $2 }')
aws configure set aws_access_key_id $(grep aws_access_key_id cli.ini | awk -F'=' '{ print $2 }')
aws configure set aws_secret_access_key $(grep aws_secret_access_key cli.ini | awk -F'=' '{ print $2 }')

### Code Packaging ###
for x in $(ls lambda); do
    zip -j lambda/${x}/${x}.zip lambda/${x}/${x}.py
done

### Terraform ###
terraform -chdir=terraform init
terraform -chdir=terraform plan -out execution_plan.tfplan

if [ -f terraform/execution_plan.tfplan ]; then
    terraform -chdir=terraform apply "execution_plan.tfplan"
fi

### Cleanup ###
for x in $(ls lambda); do
    rm lambda/${x}/${x}.zip
done