#----------------------------------------------
# IAM Roles
#----------------------------------------------
role_arn                = "arn:aws:iam::184890426414:role/TerraformExecutionRole"
admin_role_arn          = "arn:aws:iam::184890426414:user/asaf"
github_actions_role_arn = "arn:aws:iam::184890426414:role/image-gallery-github-actions-role"

#----------------------------------------------
# Naming
#----------------------------------------------
app_name     = "image-gallery"
env          = "prod"
cluster_name = "prod-eks"

#----------------------------------------------
# Network
#----------------------------------------------
vpc_cidr = "10.2.0.0/16"

public_subnets = [
  "10.2.1.0/24",
  "10.2.2.0/24"
]

private_subnets = [
  "10.2.11.0/24",
  "10.2.12.0/24"
]

#----------------------------------------------
# Node Group
#----------------------------------------------
node_instance_types = ["t3.xlrage", "t3.large"]
node_desired_size   = 3
node_max_size       = 6
node_min_size       = 2

