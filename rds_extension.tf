resource "aws_s3_object" "rds_config" {
    bucket = "fauna-admin-REPLACE_ME_UUID"
    key = "rds_config.ini"
    acl = "private"
    source = "${path.module}/rds_config.ini"
}