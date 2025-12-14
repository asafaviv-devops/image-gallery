data "tls_certificate" "oidc_cert" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer

  client_id_list = ["sts.amazonaws.com"]

  thumbprint_list = [
    data.tls_certificate.oidc_cert.certificates[0].sha1_fingerprint
  ]

  tags = merge(
    {
      Name      = "${local.prefix}-oidc"
      App       = var.app_name
      Env       = var.env
      ManagedBy = "terraform"
    },
    var.tags
  )
}

