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

resource "aws_s3_bucket" "fauna_images_bucket" {
    bucket = "fauna-images-REPLACE_ME_UUID"

    tags = {
        Name = "fauna-images-REPLACE_ME_UUID"
    }
}

resource "aws_s3_bucket_acl" "fauna_images_bucket" {
  bucket = aws_s3_bucket.fauna_images_bucket.id
  acl = "private"
}


resource "aws_s3_object" "initial_image" {
    bucket = aws_s3_bucket.fauna_images_bucket.bucket
    key = "okapi"
    acl = "private"
    source = "${path.module}/../images/okapi.jpg"
}


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


resource "aws_lambda_function" "fauna_tag_image_lambda" {
  filename = "${path.module}/../lambda/fauna-tag-image/staging/fauna-tag-image.zip"
  function_name = "fauna_tag_image-REPLACE_ME_UUID"
  role = aws_iam_role.iam_for_lambda.arn
  handler = "fauna-tag-image.tag_image"

  runtime = "python3.9"
}

resource "aws_lambda_function_url" "fauna_tag_image_lambda_function_url" {
    function_name = aws_lambda_function.fauna_tag_image_lambda.function_name
    authorization_type = "NONE"
}

output "aws_lambda_function_url" {
  value = aws_lambda_function_url.fauna_tag_image_lambda_function_url.function_url
}

