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

output "cloudwatch_dashboard_url" {
  value       = var.enable_monitoring ? "https://console.aws.amazon.com/cloudwatch/home?region=us-east-1#dashboards:name=${aws_cloudwatch_dashboard.eks[0].dashboard_name}" : null
  description = "URL to CloudWatch Dashboard (null if monitoring disabled)"
}

output "sns_topic_arn" {
  value       = var.enable_monitoring && var.alert_email != "" ? aws_sns_topic.alerts[0].arn : null
  description = "ARN of SNS topic for alerts (null if monitoring disabled or no email)"
}

output "prometheus_enabled" {
  value       = var.enable_prometheus
  description = "Whether Prometheus stack is enabled"
}

output "grafana_admin_password" {
  value       = var.enable_prometheus ? "admin" : null
  description = "Grafana admin password (change this in production!)"
  sensitive   = true
}
