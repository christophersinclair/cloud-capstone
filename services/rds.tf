
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

# Fauna RDS DB
resource "aws_db_instance" "fauna_db" {
    allocated_storage = 10
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t3.micro"
    db_name = "FaunaDB"
    username = "fauna"
    password = "${random_password.db_password.result}"
}

output "rds_endpoint" {
    value = aws_db_instance.fauna_db.endpoint
}

output "rds_arn" {
    value = aws_db_instance.fauna_db.arn
}

resource "aws_s3_object" "app_config" {
    bucket = "fauna-admin-REPLACE_ME_UUID"
    key = "app_config.ini"
    acl = "private"
    source = "${path.module}/app_config.ini"
}