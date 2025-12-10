role_arn       = "arn:aws:iam::184890426414:role/TerraformExecutionRole"
admin_role_arn = "arn:aws:iam::184890426414:user/asaf"

app_name = "image-gallery"
env      = "dev"

cluster_name = "image-gallery"

vpc_cidr = "10.0.0.0/16"

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

