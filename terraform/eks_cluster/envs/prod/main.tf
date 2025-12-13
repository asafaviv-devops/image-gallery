#----------------------------------------------
# Provider Configuration
#----------------------------------------------
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = var.role_arn
    session_name = "terraform-prod"
  }
}

#----------------------------------------------
# Network Module
#----------------------------------------------
module "network" {
  source = "../../modules/network"

  # Naming
  app_name = var.app_name
  env      = var.env

  # Network Config
  vpc_cidr              = var.vpc_cidr
  public_subnets_cidrs  = var.public_subnets
  private_subnets_cidrs = var.private_subnets

  tags = {}
}

#----------------------------------------------
# EKS Module
#----------------------------------------------
module "eks" {
  source = "../../modules/eks"

  # Naming
  app_name     = var.app_name
  env          = var.env
  cluster_name = var.cluster_name

  # Network
  vpc_id  = module.network.vpc_id
  subnets = module.network.private_subnet_ids

  # Access
  admin_role_arn          = var.admin_role_arn
  github_actions_role_arn = var.github_actions_role_arn
  terraform_role_arn      = var.role_arn

  # Node Group
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_max_size       = var.node_max_size
  node_min_size       = var.node_min_size

  # Endpoint Access
  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]

  tags = {}
}

#----------------------------------------------
# Environment Module (Kubernetes + Namespace)
#----------------------------------------------
module "environment" {
  source = "../../modules/environment"

  # EKS Cluster Info
  cluster_endpoint       = module.eks.cluster_endpoint
  cluster_ca_certificate = module.eks.cluster_ca_certificate
  cluster_name           = module.eks.cluster_name
  cluster_id             = module.eks.cluster_name

  # Terraform Role
  terraform_role_arn = var.role_arn

  # Application Config
  app_name       = var.app_name
  env            = var.env
  namespace_name = var.namespace_name
}

