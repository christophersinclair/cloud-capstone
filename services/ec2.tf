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

# EC2 -> ECS policy
resource "aws_iam_role_policy" "ec2_ecs_policy" {
    name = "iam_for_ec2_ecs-REPLACE_ME_UUID"
    role = aws_iam_role.iam_for_ec2.id
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ecs:*",
            "Resource": "arn:aws:ecs:::*"
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