# oidc.tf
# GitHub OIDC Provider

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  # GitHub's thumbprint - this rarely changes
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd" # Backup thumbprint
  ]

  tags = merge(var.tags, {
    Name = "${var.project_name}-github-oidc"
  })
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name        = "${var.project_name}-github-actions-role"
  description = "IAM role for GitHub Actions OIDC"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
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
            # Allow only from your specific repo
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-github-actions-role"
  })
}

# ========================================
# Managed Policies (Best Practice)
# ========================================

# CI Policy - ECR Push/Pull (Least Privilege)
resource "aws_iam_policy" "github_actions_ci" {
  name        = "${var.project_name}-github-actions-ci-policy"
  description = "Least privilege policy for GitHub Actions CI - ECR operations only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ECRAuthToken"
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

  tags = merge(var.tags, {
    Name = "${var.project_name}-ci-policy"
  })
}

# CD Policy - EKS Deployment (Least Privilege)
resource "aws_iam_policy" "github_actions_cd" {
  name        = "${var.project_name}-github-actions-cd-policy"
  description = "Least privilege policy for GitHub Actions CD - EKS describe only"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSDescribeCluster"
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

  tags = merge(var.tags, {
    Name = "${var.project_name}-cd-policy"
  })
}

# S3 Policy - Image Storage (Least Privilege)
resource "aws_iam_policy" "github_actions_s3" {
  name        = "${var.project_name}-github-actions-s3-policy"
  description = "Least privilege policy for GitHub Actions - S3 image storage access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketAccess"
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*-images"
      },
      {
        Sid    = "S3ObjectAccess"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::${var.project_name}-*-images/*"
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-s3-policy"
  })
}

# ========================================
# Policy Attachments
# ========================================

# Attach CI Policy to Role
resource "aws_iam_role_policy_attachment" "github_actions_ci" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_ci.arn
}

# Attach CD Policy to Role
resource "aws_iam_role_policy_attachment" "github_actions_cd" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_cd.arn
}

# Attach S3 Policy to Role
resource "aws_iam_role_policy_attachment" "github_actions_s3" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.github_actions_s3.arn
}
