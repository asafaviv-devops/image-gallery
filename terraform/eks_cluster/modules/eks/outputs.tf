output "cluster_name" {
  value = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc.arn
}

output "cluster_oidc_issuer" {
  value = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

output "alb_controller_role_arn" {
  value       = var.enable_alb_controller ? aws_iam_role.alb_controller[0].arn : null
  description = "ARN of the IAM role for AWS Load Balancer Controller (null if disabled)"
}

