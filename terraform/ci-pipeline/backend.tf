# terraform/ci-pipeline/backend.tf
# Backend configuration for remote state storage
# 
# IMPORTANT: Run terraform/bootstrap/ first to create the S3 bucket!

terraform {
  backend "s3" {
    # Bucket created by bootstrap
    bucket = "image-gallery-tfstate-184890426414"
    
    # Unique key for this project
    key = "ci-pipeline/terraform.tfstate"
    
    # Region where bucket was created
    region = "us-east-1"
    
    # Enable encryption at rest
    encrypt = true
    
    # S3 native locking (no DynamoDB needed)
    use_lockfile = true
  }
}
