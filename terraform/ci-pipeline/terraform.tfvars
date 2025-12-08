aws_region          = "us-east-1"
project_name        = "image-gallery"
github_org          = "asafaviv-devops"
github_repo         = "image-gallery"
ecr_repository_name = "image-gallery"
image_retention_count = 10

tags = {
  Project     = "image-gallery"
  ManagedBy   = "terraform"
  Environment = "production"
}
