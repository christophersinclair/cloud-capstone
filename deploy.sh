#!/bin/bash

function cleanup {
    rm -rf terraform
    for x in $(ls lambda); do
        rm -rf lambda/${x}/staging/
    done
    for x in $(ls lib); do
        if [[ ${x} == *.zip ]]; then
            rm lib/${x}
        else
            continue
        fi
    done
}

trap cleanup EXIT

###################
# This script deploys the Fauna infrastructure and application through the single execution. Because this runs
# on "A Cloud Guru" timed virtual sandboxes, the environment gets deleted every 4 hours. To avoid any data
# inconsistencies and mismatches with S3 bucket names, a random UUID is generated and hardcoded into the Terraform script
# and Lambda function with each deployment.

UUID=$(cat /proc/sys/kernel/random/uuid)
echo 'UUID: '${UUID}

### Template UUID replacement and staging
mkdir terraform
cp template.tf terraform/main.tf
sed -i -e "s/REPLACE_ME_UUID/${UUID}/g" terraform/main.tf

### Library Packaging ###
for x in $(ls lib); do
    zip -qq -r lib/${x}.zip lib/${x}
done

### Code Packaging and UUID replacement ###
for x in $(ls lambda); do
    mkdir lambda/${x}/staging/
    cp lambda/${x}/${x}.py lambda/${x}/staging/${x}.py
    sed -i -e "s/REPLACE_ME_UUID/${UUID}/g" lambda/${x}/staging/${x}.py
    zip -qq -j lambda/${x}/staging/${x}.zip lambda/${x}/staging/${x}.py
done

###################

#### AWS CLI ####
aws configure set region $(grep aws_region cli.ini | awk -F'=' '{ print $2 }')
aws configure set aws_access_key_id $(grep aws_access_key_id cli.ini | awk -F'=' '{ print $2 }')
aws configure set aws_secret_access_key $(grep aws_secret_access_key cli.ini | awk -F'=' '{ print $2 }')

### Terraform ###
terraform -chdir=terraform init
terraform -chdir=terraform plan -out execution_plan.tfplan

if [ -f terraform/execution_plan.tfplan ]; then
    terraform -chdir=terraform apply "execution_plan.tfplan"
fi


###################
### Lambda -> RDS Setup ###

cp rds_extension.tf terraform/rds_extension.tf

RDS_ENDPOINT=$(terraform -chdir=terraform output rds_endpoint)

sed -i -e "s/REPLACE_ME_UUID/${UUID}/g" terraform/rds_extension.tf

cp config/rds_config.ini terraform/
sed -i -e "s/REPLACE_ME_UUID/${UUID}/g" terraform/rds_config.ini
sed -i -e "s/REPLACE_ME_ENDPOINT/${RDS_ENDPOINT}/g" terraform/rds_config.ini
sed -i -e "s/\"//g" terraform/rds_config.ini

terraform -chdir=terraform init
terraform -chdir=terraform plan -out execution_extension.tfplan

if [ -f terraform/execution_extension.tfplan ]; then
    terraform -chdir=terraform apply "execution_extension.tfplan"
fi
