# ECS
resource "aws_ecs_cluster" "fauna-ecs-cluster" {
    name = "fauna-ecs-cluster-REPLACE_ME_UUID"
}

resource "aws_ecs_task_definition" "fauna-ecs-task-definition" {
    family = "fauna-ecs-task-definition-REPLACE_ME_UUID"
    network_mode = "awsvpc"
    memory = "1024"
    cpu = "512"
    requires_compatibilities = [ "FARGATE" ]
    execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
    task_role_arn = aws_iam_role.ecs_task_execution_role.arn
    runtime_platform {
        operating_system_family = "LINUX"
        cpu_architecture = "X86_64"
    }

    container_definitions = <<TASK_DEFINITION
[
  {
    "entryPoint": ["/bin/sh /docker-entrypoint.sh"],
    "environment": [
      {"name": "AWS_DEFAULT_REGION", "value": "REPLACE_ME_REGION"},
      {"name": "AWS_ACCESS_KEY_ID", "value": "REPLACE_ME_KEY_ID"},
      {"name": "AWS_SECRET_ACCESS_KEY", "value": "REPLACE_ME_SECRET_KEY"}
    ],
    "portMappings": [
        {
            "containerPort": 80,
            "hostPort": 80,
            "protocol": "tcp"
        }
    ],
    "memory": 1024,
    "cpu": 512,
    "essential": true,
    "image": "REPLACE_ME_ACCT_ID.dkr.ecr.REPLACE_ME_REGION.amazonaws.com/fauna-container-REPLACE_ME_UUID:latest",
    "name": "fauna-container-REPLACE_ME_UUID"
  }
]
TASK_DEFINITION
}

resource "aws_ecs_service" "fauna-ecs-service" {
    name = "fauna-ecs-service-REPLACE_ME_UUID"
    cluster = aws_ecs_cluster.fauna-ecs-cluster.id
    task_definition = aws_ecs_task_definition.fauna-ecs-task-definition.arn
    desired_count = 2
    network_configuration {
      subnets = data.aws_subnet_ids.all.ids
    }
}