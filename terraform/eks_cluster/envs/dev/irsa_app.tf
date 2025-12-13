locals {
  sa_namespace = "image-gallery"  # ✅ תוקן!
  sa_name      = "app-sa"

  prefix = "${var.app_name}-${var.env}"

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

resource "aws_iam_role_policy_attachment" "app_s3_read" {
  role       = aws_iam_role.app_sa_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"  # ✅ Full access!
}

output "app_sa_irsa_role_arn" {
  value = aws_iam_role.app_sa_irsa_role.arn
}

