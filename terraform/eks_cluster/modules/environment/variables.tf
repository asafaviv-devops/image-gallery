#----------------------------------------------
# EKS Cluster Information
#----------------------------------------------
variable "cluster_endpoint" {
  description = "EKS cluster endpoint URL"
  type        = string
}

variable "cluster_ca_certificate" {
  description = "EKS cluster certificate authority data"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_id" {
  description = "EKS cluster ID for dependency management"
  type        = string
}

#----------------------------------------------
# Terraform Role
#----------------------------------------------
variable "terraform_role_arn" {
  description = "IAM role ARN for Terraform to assume when connecting to Kubernetes"
  type        = string
}

#----------------------------------------------
# Application Configuration
#----------------------------------------------
variable "app_name" {
  description = "Application name"
  type        = string
}

variable "env" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "namespace_name" {
  description = "Kubernetes namespace name (defaults to app_name if empty)"
  type        = string
  default     = ""
}
