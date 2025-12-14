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

