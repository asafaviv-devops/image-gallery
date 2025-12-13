output "namespace_name" {
  description = "The name of the created Kubernetes namespace"
  value       = kubernetes_namespace.app.metadata[0].name
}

output "namespace_id" {
  description = "The ID of the created Kubernetes namespace"
  value       = kubernetes_namespace.app.id
}
