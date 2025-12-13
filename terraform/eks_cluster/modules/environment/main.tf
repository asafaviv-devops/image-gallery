#----------------------------------------------
# Kubernetes Provider Configuration
#----------------------------------------------
provider "kubernetes" {
  host                   = var.cluster_endpoint
  cluster_ca_certificate = base64decode(var.cluster_ca_certificate)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = [
      "eks",
      "get-token",
      "--cluster-name",
      var.cluster_name,
      "--role-arn",
      var.terraform_role_arn
    ]
  }
}

#----------------------------------------------
# Kubernetes Namespace
#----------------------------------------------
locals {
  namespace_name = var.namespace_name != "" ? var.namespace_name : var.app_name
}

resource "kubernetes_namespace_v1" "app" {
  metadata {
    name = local.namespace_name

    labels = {
      name        = local.namespace_name
      environment = var.env
      managed-by  = "terraform"
      app         = var.app_name
    }
  }

  depends_on = [var.cluster_id]
}
