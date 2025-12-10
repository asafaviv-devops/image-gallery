role_arn                = "arn:aws:iam::184890426414:role/TerraformExecutionRole"
admin_role_arn          = "arn:aws:iam::184890426414:user/asaf"
github_actions_role_arn = "arn:aws:iam::184890426414:role/image-gallery-github-actions-role"

app_name = "hello-world"
env      = "staging"

cluster_name = "staging-eks"

vpc_cidr = "10.1.0.0/16"

public_subnets = [
  "10.1.1.0/24",
  "10.1.2.0/24"
]

private_subnets = [
  "10.1.11.0/24",
  "10.1.12.0/24"
]

