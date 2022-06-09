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

resource "aws_iam_instance_profile" "ec2_profile" {
    name = "ec2_profile-REPLACE_ME_UUID"
    role = aws_iam_role.iam_for_ec2.name
}


# ECS
resource "aws_iam_role" "ecs_task_execution_role" {
    name = "ecs-task-execution-role-REPLACE_ME_UUID"

    assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
    },
    "Effect": "Allow",
    "Sid": ""
   }
 ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-execution-role-policy-attachment" {
    role = aws_iam_role.ecs_task_execution_role.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}