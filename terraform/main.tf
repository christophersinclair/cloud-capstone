terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
        }
    }
}

variable "aws_region" {
    default = "us-east-1"
}

provider "aws" {
    profile = "default"
    shared_credentials_files = ["/home/sinclair/.aws/credentials"]
    shared_config_files = ["/home/sinclair/.aws/config"]
    region = var.aws_region
}

resource "aws_default_vpc" "default" {}

data "aws_ami" "alx" {
    most_recent = true
    owners = ["amazon"]
}

resource "aws_instance" "ex" {
    ami = "data.aws_ami.alx.id"
    instance_type = "t2.micro"
}

output "aws_public_ip" {
    value = "aws_instance.ex.public_dns"
}