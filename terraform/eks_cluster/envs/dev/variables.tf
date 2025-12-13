#----------------------------------------------
# IAM Roles
#----------------------------------------------
variable "role_arn" {
  description = "IAM role ARN for Terraform to assume when creating resources"
  type        = string
}

variable "admin_role_arn" {
  description = "IAM user/role ARN for EKS cluster admin access (kubectl)"
  type        = string
}

variable "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions CI/CD to access EKS"
  type        = string
  default     = ""
}

#----------------------------------------------
# Naming
#----------------------------------------------
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

#----------------------------------------------
# Network
#----------------------------------------------
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

#----------------------------------------------
# Node Group
#----------------------------------------------
variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
}

variable "node_max_size" {
  description = "Maximum number of worker nodes for autoscaling"
  type        = number
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
}
