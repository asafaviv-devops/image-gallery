#----------------------------------------------
# Naming
#----------------------------------------------
variable "app_name" {
  description = "Application name used for naming and tagging AWS resources"
  type        = string
}

variable "env" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.env)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "cluster_name" {
  description = "Logical cluster name (combined with app and env for naming)"
  type        = string
}

variable "tags" {
  description = "Additional tags to add to all EKS resources"
  type        = map(string)
  default     = {}
}

#----------------------------------------------
# Network
#----------------------------------------------
variable "vpc_id" {
  description = "VPC ID where EKS cluster will be created"
  type        = string
}

variable "subnets" {
  description = "Subnet IDs for EKS control plane and worker nodes"
  type        = list(string)
}

#----------------------------------------------
# EKS Endpoint Access
#----------------------------------------------
variable "endpoint_private_access" {
  description = "Whether the EKS API endpoint should be accessible from private subnets"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Whether the EKS API endpoint should be publicly accessible"
  type        = bool
  default     = true
}

variable "public_access_cidrs" {
  description = "CIDR blocks allowed to access the public EKS endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

#----------------------------------------------
# IAM Access
#----------------------------------------------
variable "admin_role_arn" {
  description = "IAM role/user ARN for EKS admin access (kubectl)"
  type        = string
  default     = ""
}

variable "github_actions_role_arn" {
  description = "IAM role ARN for GitHub Actions CD"
  type        = string
  default     = ""
}

#----------------------------------------------
# Node Group
#----------------------------------------------
variable "node_instance_types" {
  description = "EC2 instance types for EKS worker nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes for autoscaling"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

#----------------------------------------------
# AWS Load Balancer Controller
#----------------------------------------------
variable "enable_alb_controller" {
  description = "Enable AWS Load Balancer Controller IRSA role"
  type        = bool
  default     = false
}
