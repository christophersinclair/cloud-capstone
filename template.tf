terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
}

provider "aws" {
    profile = "default"
    shared_credentials_files = ["~/.aws/credentials"]
    shared_config_files = ["~/.aws/config"]
}

resource "aws_default_vpc" "default" {}

data "aws_security_group" "default_sg" {
    filter {
      name = "description"
      values = [ "*default*" ]
    }

    filter {
        name = "vpc-id"
        values = [ "${aws_default_vpc.default.id}" ]
    }
}

data "aws_subnet_ids" "all" {
    vpc_id = aws_default_vpc.default.id
}


# Generate password for RDS
resource "random_password" "db_password" {
    length = 16
    special = true
    override_special = "_%"
}

# Store password in AWS Secrets Manager
resource "aws_secretsmanager_secret" "fauna_db_secret" {
    name = "fauna_db_secret-REPLACE_ME_UUID"
}

resource "aws_secretsmanager_secret_version" "sversion" {
    secret_id = aws_secretsmanager_secret.fauna_db_secret.id
    secret_string = <<EOF
{
    "username": "fauna",
    "password": "${random_password.db_password.result}"
}
EOF
}

output db_password {
    value = random_password.db_password.result
    sensitive = true
}

output secret_arn {
    value = aws_secretsmanager_secret_version.sversion.arn
}


# Fauna application S3 bucket
resource "aws_s3_bucket" "fauna_images_bucket" {
    bucket = "fauna-images-REPLACE_ME_UUID"

    tags = {
        Name = "fauna-images-REPLACE_ME_UUID"
    }
}

resource "aws_s3_bucket_acl" "fauna_images_bucket_acl" {
    bucket = aws_s3_bucket.fauna_images_bucket.id
    acl = "private"
}

resource "aws_s3_object" "initial_image" {
    bucket = aws_s3_bucket.fauna_images_bucket.bucket
    key = "0519/okapi"
    acl = "private"
    source = "${path.module}/../images/okapi.jpg"
}


# Fauna administrator S3 bucket
resource "aws_s3_bucket" "fauna_admin_bucket" {
    bucket = "fauna-admin-REPLACE_ME_UUID"

    tags = {
        Name = "fauna-admin-REPLACE_ME_UUID"
    }
}

resource "aws_s3_bucket_acl" "fauna_admin_bucket_acl" {
    bucket = aws_s3_bucket.fauna_admin_bucket.id
    acl = "private"
}


# Lambda -> S3 policy
resource "aws_iam_policy" "lambda_s3_policy" {
    name = "iam_for_lambda_s3-REPLACE_ME_UUID"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": "arn:aws:s3:::*"
        }
    ]
}
EOF
}

resource "aws_iam_policy" "lambda_rds_policy" {
    name = "iam_for_lambda_rds-REPLACE_ME_UUID"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "rds-data:*",
            "Resource": "arn:aws:rds:::*"
        }
    ]
}
EOF
}


# Lambda role
resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda-REPLACE_ME_UUID"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid":""
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "lambda-s3-attach" {
    role = aws_iam_role.iam_for_lambda.name
    policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda-rds-attach" {
    role = aws_iam_role.iam_for_lambda.name
    policy_arn = aws_iam_policy.lambda_rds_policy.arn
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
    role       = aws_iam_role.iam_for_lambda.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# Lambda Python module layer
resource "aws_lambda_layer_version" "fauna-lambda-db-layer" {
    filename = "${path.module}/../lib/layer.zip"
    layer_name = "fauna-lambda-db-layer-REPLACE_ME_UUID"
    compatible_runtimes = [ "python3.9" ]
}


# Lambda tag-image function
resource "aws_lambda_function" "fauna_tag_image_lambda" {
    filename = "${path.module}/../lambda/fauna-tag-image/staging/fauna-tag-image.zip"
    function_name = "fauna_tag_image-REPLACE_ME_UUID"
    role = aws_iam_role.iam_for_lambda.arn
    handler = "fauna-tag-image.tag_image"
    layers = [ aws_lambda_layer_version.fauna-lambda-db-layer.arn ]
    timeout = 30

    vpc_config {
      security_group_ids = ["${data.aws_security_group.default_sg.id}"]
      subnet_ids = ["${tolist(data.aws_subnet_ids.all.ids)[0]}"]
    }

    runtime = "python3.9"
}

resource "aws_lambda_function_url" "fauna_tag_image_lambda_function_url" {
    function_name = aws_lambda_function.fauna_tag_image_lambda.function_name
    authorization_type = "NONE"
}

output "aws_lambda_function_url" {
    value = aws_lambda_function_url.fauna_tag_image_lambda_function_url.function_url
}


# Fauna RDS DB
resource "aws_db_instance" "fauna_db" {
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t3.micro"
    db_name = "FaunaDB"
    username = "fauna"
    password = "${random_password.db_password.result}"
}

output "rds_endpoint" {
    value = aws_db_instance.fauna_db.endpoint
}

output "rds_arn" {
    value = aws_db_instance.fauna_db.arn
}