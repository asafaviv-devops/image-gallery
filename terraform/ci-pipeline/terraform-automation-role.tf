# GitHub Actions OIDC Role with Least Privilege
# Replaces: terraform/ci-pipeline/terraform-automation-role.tf

# Combined role for both CI and CD workflows
resource "aws_iam_role" "github_actions" {
  name = "${var.project_name}-github-actions-role"

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
    Name = "${var.project_name}-github-actions-role"
  })
}

# CI Policy - ECR Push
resource "aws_iam_policy" "github_actions_ci" {
  name        = "${var.project_name}-github-actions-ci-policy"
  description = "Least privilege policy for GitHub Actions CI (ECR push)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthentication"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRImageManagement"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:PutImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = "arn:aws:ecr:*:*:repository/${var.project_name}*"
      },
      {
        Sid    = "STSIdentity"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# CD Policy - EKS Deployment
resource "aws_iam_policy" "github_actions_cd" {
  name        = "${var.project_name}-github-actions-cd-policy"
  description = "Least privilege policy for GitHub Actions CD (EKS deployment)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSDescribe"
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "eks:DescribeNodegroup",
          "eks:ListNodegroups"
        ]
        Resource = "arn:aws:eks:*:*:cluster/${var.project_name}-*"
      },
      {
        Sid    = "STSIdentity"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach both policies to the role
resource "aws_iam_role_policy_attachment" "github_actions_ci" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ci.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_cd" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_cd.arn
}

# Outputs
output "github_actions_role_arn" {
  description = "ARN of IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.name
}

output "github_actions_ci_policy_arn" {
  description = "ARN of CI policy"
  value       = aws_iam_policy.github_actions_ci.arn
}

output "github_actions_cd_policy_arn" {
  description = "ARN of CD policy"
  value       = aws_iam_policy.github_actions_cd.arn
}
