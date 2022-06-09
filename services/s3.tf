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
    source = "${path.module}/../application/nature_template.zip"
}