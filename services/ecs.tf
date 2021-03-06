# ECS
resource "aws_ecs_cluster" "fauna-ecs-cluster" {
    name = "fauna-ecs-cluster-REPLACE_ME_UUID"
}

resource "aws_cloudwatch_log_group" "fauna-container-logs" {
    name = "fauna-container-logs-REPLACE_ME_UUID"
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
    depends_on = [
      aws_cloudwatch_log_group.fauna-container-logs
    ]
    container_definitions = <<TASK_DEFINITION
[
  {
    "command": ["/docker-entrypoint.sh"],
    "environment": [
      {"name": "AWS_DEFAULT_REGION", "value": "${data.aws_region.current.name}"},
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
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "fauna-container-logs-REPLACE_ME_UUID",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "awslogs-fauna"
      }
    },
    "memory": 1024,
    "cpu": 512,
    "essential": true,
    "image": "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/fauna-container-REPLACE_ME_UUID:latest",
    "name": "fauna-container-REPLACE_ME_UUID"
  }
]
TASK_DEFINITION
}

resource "aws_ecs_service" "fauna-ecs-service" {
    name = "fauna-ecs-service-REPLACE_ME_UUID"
    cluster = aws_ecs_cluster.fauna-ecs-cluster.id
    task_definition = aws_ecs_task_definition.fauna-ecs-task-definition.arn
    launch_type = "FARGATE"
    platform_version = "1.3.0"
    desired_count = 2
    network_configuration {
      subnets = data.aws_subnet_ids.all.ids
      assign_public_ip = true
    }
}