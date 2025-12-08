# variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "image-gallery"
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
  # Example: "yourusername" or "your-org"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  # Example: "image-gallery"
}

variable "ecr_repository_name" {
  description = "ECR repository name"
  type        = string
  default     = "image-gallery"
}

variable "image_retention_count" {
  description = "Number of images to retain in ECR"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Project     = "image-gallery"
    ManagedBy   = "terraform"
    Environment = "production"
  }
}
