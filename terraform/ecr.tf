resource "aws_ecr_repository" "repository" {
  name                 = "app"
  image_tag_mutability = "MUTABLE"
}