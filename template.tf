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

resource "tls_private_key" "fauna-private-key" {
    algorithm = "RSA"
    rsa_bits = 4096
}

resource "aws_key_pair" "generated_key" {
    key_name = "fauna-private-key"
    public_key = tls_private_key.fauna-private-key.public_key_openssh
}

resource "aws_network_interface" "fauna-interface" {
    subnet_id = tolist(data.aws_subnet_ids.all.ids)[0]
}

resource "aws_security_group" "allow_ssh" {
    name = "allow-fauna-ssh-REPLACE_ME_UUID"
    description = "Allow ports"
    vpc_id = aws_default_vpc.default.id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = [ "0.0.0.0/0" ]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = [ "0.0.0.0/0" ]
    }
} 


resource "aws_instance" "base-fauna" {
    ami = data.aws_ami.alx.id
    instance_type = "t3.micro"
    key_name = aws_key_pair.generated_key.key_name
    vpc_security_group_ids = [ aws_security_group.allow_ssh.id ]

    # network_interface {
    #   network_interface_id = aws_network_interface.fauna-interface.id
    #   device_index = 0
    # }

    iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = tls_private_key.fauna-private-key.private_key_pem
    }
    provisioner "remote-exec" {
        inline = [
            "sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm",
            "sudo systemctl start amazon-ssm-agent",
            "sudo yum update -y",
            "sudo yum install -y httpd",
            "sudo /usr/bin/aws s3api get-object --bucket fauna-admin-REPLACE_ME_UUID --key nature_template.zip /var/www/html/nature_template.zip",
            "sudo unzip /var/www/html/nature_template.zip -d /var/www/html/",
            "sudo systemctl start httpd"
        ]
    }

    depends_on = [
        aws_s3_object.html_template
    ]

    tags = {
      "Name" = "Fauna"
    }
}

output "public_dns" {
    value = aws_instance.base-fauna.public_dns
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

resource "aws_s3_object" "html_template" {
    bucket = aws_s3_bucket.fauna_admin_bucket.bucket
    key = "nature_template.zip"
    acl = "private"
    source = "${path.module}/../nature_template.zip"
}

# EC2 -> S3 policy
resource "aws_iam_role_policy" "ec2_s3_policy" {
    name = "iam_for_ec2_s3-REPLACE_ME_UUID"
    role = aws_iam_role.iam_for_ec2.id
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

# EC2 role
resource "aws_iam_role" "iam_for_ec2" {
    name = "iam_for_ec2-REPLACE_ME_UUID"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid":""
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_profile"
    role = aws_iam_role.iam_for_ec2.name
}

# resource "aws_iam_role_policy_attachment" "lambda-rds-attach" {
#     role = aws_iam_role.iam_for_lambda.name
#     policy_arn = aws_iam_policy.lambda_rds_policy.arn
# }

# resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole" {
#     role       = aws_iam_role.iam_for_lambda.name
#     policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
# }


# # Fauna RDS DB
# resource "aws_db_instance" "fauna_db" {
#     allocated_storage = 10
#     engine = "mysql"
#     engine_version = "5.7"
#     instance_class = "db.t3.micro"
#     db_name = "FaunaDB"
#     username = "fauna"
#     password = "${random_password.db_password.result}"
# }

# output "rds_endpoint" {
#     value = aws_db_instance.fauna_db.endpoint
# }

# output "rds_arn" {
#     value = aws_db_instance.fauna_db.arn
# }