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

variable "cluster_name" {
  type        = string
  description = "Logical cluster name (combined with app and env for naming)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS cluster will be created."
}

variable "subnets" {
  type        = list(string)
  description = "Subnet IDs for EKS control plane and worker nodes."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Additional tags to add to all EKS resources."
}

variable "endpoint_private_access" {
  type        = bool
  default     = true
  description = "Whether the EKS API endpoint should be accessible from private subnets."
}

variable "endpoint_public_access" {
  type        = bool
  default     = true
  description = "Whether the EKS API endpoint should be publicly accessible."
}

variable "public_access_cidrs" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "CIDR blocks allowed to access the public EKS endpoint."
}

