# ECR
resource "aws_ecr_repository" "fauna-ecr-repository" {
    name = "fauna-container-REPLACE_ME_UUID"
    image_tag_mutability = "IMMUTABLE"
}