#----------------------------------------------
# IAM Roles
#----------------------------------------------
role_arn                = "arn:aws:iam::184890426414:role/TerraformExecutionRole"
admin_role_arn          = "arn:aws:iam::184890426414:user/asaf_aviv"
github_actions_role_arn = "arn:aws:iam::184890426414:role/image-gallery-github-actions-role"

#----------------------------------------------
# Naming
#----------------------------------------------
app_name     = "image-gallery"
env          = "dev"
cluster_name = "image-gallery"

#----------------------------------------------
# Network
#----------------------------------------------
vpc_cidr = "10.0.0.0/16"

public_subnets = [
  "10.0.1.0/24",
  "10.0.2.0/24"
]

private_subnets = [
  "10.0.11.0/24",
  "10.0.12.0/24"
]

#----------------------------------------------
# Node Group
#----------------------------------------------
node_instance_types = ["t3.medium"]
node_desired_size   = 1
node_max_size       = 2
node_min_size       = 1

#----------------------------------------------
# Monitoring & Alerts
#----------------------------------------------
alert_email = "your-email@example.com"  # שנה לכתובת המייל שלך
