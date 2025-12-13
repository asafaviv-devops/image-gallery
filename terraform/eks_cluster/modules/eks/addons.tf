##############################################################
# EKS OFFICIAL ADDONS (vpc-cni, kube-proxy, coredns)
##############################################################

locals {
  addon_tags = merge(
    var.tags,
    {
      App       = var.app_name
      Env       = var.env
      ManagedBy = "terraform"
    }
  )
}

# ---- VPC CNI ----
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_update = "PRESERVE"

  tags = merge(
    local.addon_tags,
    {
      Name = "${local.prefix}-addon-vpc-cni"
    }
  )

  depends_on = [
    aws_eks_cluster.this
  ]
}

# ---- kube-proxy ----
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_update = "PRESERVE"


  tags = merge(
    local.addon_tags,
    {
      Name = "${local.prefix}-addon-kube-proxy"
    }
  )

  depends_on = [
    aws_eks_cluster.this
  ]
}

# ---- CoreDNS ----
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.this.name
  addon_name                  = "coredns"
  resolve_conflicts_on_update = "PRESERVE"


  tags = merge(
    local.addon_tags,
    {
      Name = "${local.prefix}-addon-coredns"
    }
  )

  depends_on = [
    aws_eks_cluster.this
  ]
}

# ---- EBS CSI Driver ----
# IAM Role for EBS CSI Driver
data "aws_iam_policy_document" "ebs_csi_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name               = "${local.prefix}-ebs-csi-driver-role"
  assume_role_policy = data.aws_iam_policy_document.ebs_csi_trust.json

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-ebs-csi-driver-role"
    }
  )
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

resource "aws_eks_addon" "ebs_csi" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi.arn

  tags = merge(
    local.addon_tags,
    {
      Name = "${local.prefix}-addon-ebs-csi"
    }
  )

  depends_on = [
    aws_eks_cluster.this,
    aws_iam_role_policy_attachment.ebs_csi
  ]
}
