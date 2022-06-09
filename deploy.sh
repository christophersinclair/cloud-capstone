#!/bin/bash

function cleanup() {
    rm -rf terraform
    docker system prune -f
}

trap cleanup EXIT

function replacement() {
    SERVICE=$1

    cp services/${SERVICE}.tf terraform/
    
    if cat terraform/${SERVICE}.tf | grep -q "REPLACE_ME_UUID"; then
        sed -i -e "s/REPLACE_ME_UUID/${UUID}/g" terraform/${SERVICE}.tf
    fi
    if cat terraform/${SERVICE}.tf | grep -q "REPLACE_ME_REGION"; then
        sed -i -e "s/REPLACE_ME_REGION/${AWS_REGION}/g" terraform/${SERVICE}.tf
    fi
    if cat terraform/${SERVICE}.tf | grep -q "REPLACE_ME_KEY_ID"; then
        sed -i -e "s/REPLACE_ME_KEY_ID/${AWS_ACCESS_KEY_ID}/g" terraform/${SERVICE}.tf
    fi
    if cat terraform/${SERVICE}.tf | grep -q "REPLACE_ME_SECRET_KEY"; then
        sed -i -e "s/REPLACE_ME_SECRET_KEY/${AWS_SECRET_ACCESS_KEY}/g" terraform/${SERVICE}.tf
    fi
    if cat terraform/${SERVICE}.tf | grep -q "REPLACE_ME_ACCT_ID"; then
        sed -i -e "s/REPLACE_ME_ACCT_ID/${AWS_ACCOUNT_ID}/g" terraform/${SERVICE}.tf
    fi
    
}

function deploy_service() {
    SERVICE=$1

    if [ ! -f terraform/${SERVICE}.tf ]; then
        replacement ${SERVICE}
    fi

    terraform -chdir=terraform init
    terraform -chdir=terraform plan -out ${SERVICE}.tfplan

    if [ -f terraform/${SERVICE}.tfplan ]; then
        terraform -chdir=terraform apply "${SERVICE}.tfplan"
    fi

}

###################
# This script deploys the Fauna infrastructure and application through the single execution. Because this runs
# on "A Cloud Guru" timed virtual sandboxes, the environment gets deleted every 4 hours. To avoid any data
# inconsistencies and mismatches with S3 bucket names, a random UUID is generated and hardcoded into the Terraform script
# and Lambda function with each deployment.

UUID=$(cat /proc/sys/kernel/random/uuid)
echo 'UUID: '${UUID}

########################
#### AWS CLI ####
#######################
AWS_REGION=$(grep aws_region cli.ini | awk -F'=' '{ print $2 }' )
AWS_ACCESS_KEY_ID=$(grep aws_access_key_id cli.ini | awk -F'=' '{ print $2 }')
AWS_SECRET_ACCESS_KEY=$(grep aws_secret_access_key cli.ini | awk -F'=' '{ print $2 }')

aws configure set region ${AWS_REGION}
aws configure set aws_access_key_id ${AWS_ACCESS_KEY_ID}
aws configure set aws_secret_access_key ${AWS_SECRET_ACCESS_KEY}

# Terraform deployments
mkdir terraform
cp services/initial.tf terraform/
terraform -chdir=terraform init

deploy_service initial
deploy_service iam
deploy_service ecr
deploy_service s3
deploy_service ec2
deploy_service rds

AWS_ACCOUNT_ID=$(terraform -chdir=terraform output account_id | sed -e "s/\"//g")

# ECS/ECR Docker container push
aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com
docker build application/ --file application/Dockerfile --tag fauna-container-${UUID}
docker tag fauna-container-${UUID}:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fauna-container-${UUID}:latest
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/fauna-container-${UUID}:latest

deploy_service ecs

echo 'Fauna website: '$(terraform -chdir=terraform output public_dns)