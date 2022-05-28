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

resource "aws_iam_role" "iam_for_lambda" {
    name = "iam_for_lambda"

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

resource "aws_lambda_function" "fauna_tag_image_lambda" {
  filename = "${path.module}/../lambda/fauna-tag-image/fauna-tag-image.zip"
  function_name = "fauna_tag_image"
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