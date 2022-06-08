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

data "aws_caller_identity" "current" {}

output "account_id" {
    value = data.aws_caller_identity.current.account_id
}

resource "aws_default_vpc" "default" {}

### All data needed from AWS
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

data "aws_ami" "alx" {
    most_recent = true
    owners = [ "amazon" ]

    filter {
        name = "name"
        values = ["amzn2-ami-hvm*"]
    }

    filter {
        name = "architecture"
        values = [ "x86_64" ]
    }
}