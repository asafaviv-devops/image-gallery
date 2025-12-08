# main.tf

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  # Optional: Use S3 backend for state
  # backend "s3" {
  #   bucket = "my-terraform-state-bucket"
  #   key    = "image-gallery/ci-pipeline/terraform.tfstate"
  #   region = "us-east-1"
  # }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = var.tags
  }
}

# Get AWS account ID
data "aws_caller_identity" "current" {}

# Get AWS region
data "aws_region" "current" {}
