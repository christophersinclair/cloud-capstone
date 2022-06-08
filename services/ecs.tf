# ECS
resource "aws_ecs_cluster" "fauna-ecs-cluster" {
    name = "fauna-ecs-cluster-REPLACE_ME_UUID"
}

resource "aws_ecs_task_definition" "fauna-ecs-task-definition" {
    family = "fauna-ecs-task-definition-REPLACE_ME_UUID"
    network_mode = "awsvpc"
    memory = "1024"
    cpu = "512"
    container_definitions = <<TASK_DEFINITION
[
  {
    "entryPoint": ["/"],
    "environment": [
      {"name": "AWS_DEFAULT_REGION", "value": "REPLACE_ME_REGION"},
      {"name": "AWS_ACCESS_KEY_ID", "value": "REPLACE_ME_KEY_ID"},
      {"name": "AWS_SECRET_ACCESS_KEY", "value": "REPLACE_ME_SECRET_KEY"}
    ],
    "memory": 1024,
    "cpu": 512,
    "essential": true,
    "image": "REPLACE_ME_ACCT_ID.dkr.ecr.REPLACE_ME_REGION.amazonaws.com/fauna-container-REPLACE_ME_UUID:latest",
    "name": "fauna-container"
  }
]
TASK_DEFINITION
}

resource "aws_ecs_service" "fauna-ecs-service" {
    name = "fauna-ecs-service-REPLACE_ME_UUID"
    cluster = aws_ecs_cluster.fauna-ecs-cluster.id
    task_definition = aws_ecs_task_definition.fauna-ecs-task-definition.arn
    desired_count = 2
    launch_type = "FARGATE"
    network_configuration {
      subnets = tolist(data.aws_subnet_ids.all.name)[0]
    }
    iam_role = aws_iam_role.iam_for_ec2.arn
    depends_on = [
      aws_iam_role_policy.ec2_ecs_policy
    ]
}