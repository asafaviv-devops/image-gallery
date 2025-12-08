role_arn = "arn:aws:iam::184890426414:role/TerraformExecutionRole"
app_name = "hello-world"
env      = "prod"

cluster_name = "prod-eks"

vpc_cidr = "10.2.0.0/16"

public_subnets = [
  "10.2.1.0/24",
  "10.2.2.0/24"
]

private_subnets = [
  "10.2.11.0/24",
  "10.2.12.0/24"
]

