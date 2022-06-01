resource "aws_s3_object" "app_config" {
    bucket = "fauna-admin-REPLACE_ME_UUID"
    key = "app_config.ini"
    acl = "private"
    source = "${path.module}/app_config.ini"
}