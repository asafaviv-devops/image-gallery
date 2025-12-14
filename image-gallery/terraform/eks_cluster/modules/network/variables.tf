variable "app_name" {
  type        = string
  description = "Application name used for naming and tagging AWS resources."
}

variable "env" {
  type        = string
  description = "Deployment environment (dev, staging, prod)."

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC."
}

variable "public_subnets_cidrs" {
  type        = list(string)
  description = "CIDR blocks for public subnets inside the VPC."
}

variable "private_subnets_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets inside the VPC."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to add to all resources."
}

