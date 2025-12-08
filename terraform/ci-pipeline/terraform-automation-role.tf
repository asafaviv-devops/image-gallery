# terraform-automation-role.tf
# IAM Role for Terraform automation via GitHub Actions

resource "aws_iam_role" "terraform_automation" {
  name = "${var.project_name}-terraform-automation-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
        }
      }
    }]
  })
  
  tags = merge(var.tags, {
    Name = "${var.project_name}-terraform-automation-role"
  })
}

# Policy for Terraform to manage infrastructure
# WARNING: This grants AdministratorAccess - use with caution!
# For production, create a custom policy with least privilege
resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.terraform_automation.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Output for GitHub Secret
output "terraform_automation_role_arn" {
  description = "ARN of IAM role for Terraform automation in GitHub Actions"
  value       = aws_iam_role.terraform_automation.arn
}

output "terraform_automation_role_name" {
  description = "Name of IAM role for Terraform automation"
  value       = aws_iam_role.terraform_automation.name
}
