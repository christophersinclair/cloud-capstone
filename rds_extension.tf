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

resource "aws_s3_object" "rds_config" {
    bucket = "fauna-admin-REPLACE_ME_UUID"
    key = "rds_config.ini"
    acl = "private"
    source = "${path.module}/../config/rds_config.ini"
}