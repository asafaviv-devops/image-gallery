variable "role_arn" {}
variable "app_name" {
  type        = string
  description = "Application name used for naming AWS resources."
}

variable "env" {
  type        = string
  description = "Deployment environment (dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cluster_name" {
  type        = string
  description = "Logical name for the EKS cluster."
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnets" {
  type        = list(string)
  description = "CIDRs for public subnets."
}

variable "private_subnets" {
  type        = list(string)
  description = "CIDRs for private subnets."
}
