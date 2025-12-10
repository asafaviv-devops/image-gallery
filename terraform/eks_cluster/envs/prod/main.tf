provider "aws" {
  region = "us-east-1"

  assume_role {
    role_arn     = var.role_arn
    session_name = "terraform-prod"
  }
}

module "network" {
  source = "../../modules/network"

  app_name = var.app_name
  env      = var.env

  vpc_cidr              = var.vpc_cidr
  public_subnets_cidrs  = var.public_subnets
  private_subnets_cidrs = var.private_subnets

  tags = {}
}

module "eks" {
  source = "../../modules/eks"

  app_name = var.app_name
  env      = var.env

  cluster_name = var.cluster_name
  vpc_id       = module.network.vpc_id
  subnets      = module.network.private_subnet_ids

  admin_role_arn = var.admin_role_arn
  github_actions_role_arn = var.github_actions_role_arn

  tags = {}

  endpoint_private_access = true
  endpoint_public_access  = true
  public_access_cidrs     = ["0.0.0.0/0"]
}

