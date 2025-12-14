locals {
  sa_namespace = var.app_name
  sa_name      = var.app_name

  prefix = "${var.app_name}-${var.env}"

  # Generic S3 bucket name - calculated from app_name and env
  s3_bucket_name = "${var.app_name}-${var.env}-images"

  issuer_no_https = replace(
    module.eks.cluster_oidc_issuer,
    "https://",
    ""
  )
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.issuer_no_https}:sub"
      values = [
        "system:serviceaccount:${local.sa_namespace}:${local.sa_name}"
      ]
    }
  }
}

resource "aws_iam_role" "app_sa_irsa_role" {
  name               = "${local.prefix}-app-sa-role"
  assume_role_policy = data.aws_iam_policy_document.trust.json

  tags = {
    App       = var.app_name
    Env       = var.env
    ManagedBy = "terraform"
    Name      = "${local.prefix}-app-sa-role"
  }
}

# Least privilege S3 policy - scoped to specific bucket only
data "aws_iam_policy_document" "s3_access" {
  statement {
    sid    = "ListBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}"
    ]
  }

  statement {
    sid    = "ObjectAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${local.s3_bucket_name}/*"
    ]
  }
}

resource "aws_iam_policy" "app_s3_access" {
  name        = "${local.prefix}-s3-access"
  description = "Least privilege S3 access for ${var.app_name} in ${var.env}"
  policy      = data.aws_iam_policy_document.s3_access.json

  tags = {
    App       = var.app_name
    Env       = var.env
    ManagedBy = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "app_s3_access" {
  role       = aws_iam_role.app_sa_irsa_role.name
  policy_arn = aws_iam_policy.app_s3_access.arn
}

output "app_sa_irsa_role_arn" {
  value = aws_iam_role.app_sa_irsa_role.arn
}

