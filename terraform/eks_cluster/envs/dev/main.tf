#----------------------------------------------
# Provider Configuration
#----------------------------------------------
provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = var.role_arn
    session_name = "terraform-dev"
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
# Kubernetes Provider (connects to EKS cluster)
#----------------------------------------------
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      module.eks.cluster_name,
      "--role-arn",
      var.role_arn
    ]
  }
}

#----------------------------------------------
# Kubernetes Namespace (Infrastructure as Code)
#----------------------------------------------
resource "kubernetes_namespace" "app" {
  metadata {
    name = "image-gallery"

    labels = {
      name        = "image-gallery"
      environment = var.env
      managed-by  = "terraform"
    }
  }

  depends_on = [module.eks]
}
