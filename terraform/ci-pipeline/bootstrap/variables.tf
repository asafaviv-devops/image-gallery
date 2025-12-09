# terraform/bootstrap/variables.tf

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name (used in bucket naming)"
  type        = string
  default     = "image-gallery"
}
