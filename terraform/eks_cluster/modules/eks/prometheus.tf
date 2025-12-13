#----------------------------------------------
# Prometheus and Grafana Stack
#----------------------------------------------

locals {
  prometheus_namespace = "monitoring"
}

#----------------------------------------------
# Prometheus Operator (kube-prometheus-stack)
#----------------------------------------------

resource "helm_release" "kube_prometheus_stack" {
  count = var.enable_prometheus ? 1 : 0

  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = local.prometheus_namespace
  version    = "56.0.0"

  create_namespace = true

  values = [
    yamlencode({
      # Prometheus Configuration
      prometheus = {
        prometheusSpec = {
          retention = var.env == "prod" ? "30d" : "15d"

          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = var.env == "prod" ? "50Gi" : "20Gi"
                  }
                }
              }
            }
          }

          # Service Monitor Selector - scrape all ServiceMonitors
          serviceMonitorSelectorNilUsesHelmValues = false
          serviceMonitorSelector                  = {}

          # Pod Monitor Selector
          podMonitorSelectorNilUsesHelmValues = false
          podMonitorSelector                  = {}

          # Resources
          resources = {
            requests = {
              cpu    = "500m"
              memory = "2Gi"
            }
            limits = {
              cpu    = "2000m"
              memory = "4Gi"
            }
          }
        }

        service = {
          type = "ClusterIP"
        }
      }

      # Grafana Configuration
      grafana = {
        enabled = true

        adminPassword = "admin" # Change this in production!

        service = {
          type = "LoadBalancer"
          annotations = {
            "service.beta.kubernetes.io/aws-load-balancer-type" = "nlb"
            "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
          }
        }

        persistence = {
          enabled = true
          size    = "10Gi"
        }

        resources = {
          requests = {
            cpu    = "100m"
            memory = "128Mi"
          }
          limits = {
            cpu    = "500m"
            memory = "512Mi"
          }
        }

        # Grafana Dashboards
        dashboardProviders = {
          "dashboardproviders.yaml" = {
            apiVersion = 1
            providers = [
              {
                name      = "default"
                orgId     = 1
                folder    = ""
                type      = "file"
                disableDeletion = false
                editable  = true
                options = {
                  path = "/var/lib/grafana/dashboards/default"
                }
              }
            ]
          }
        }

        dashboards = {
          default = {
            # Image Gallery Application Dashboard
            image-gallery-app = {
              gnetId = 0
              json   = jsonencode({
                annotations = {
                  list = []
                }
                title       = "Image Gallery Application Metrics"
                uid         = "image-gallery-app"
                editable    = true
                panels = [
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "Request Rate"
                    type      = "graph"
                    gridPos   = { h = 8, w = 12, x = 0, y = 0 }
                    targets = [
                      {
                        expr = "rate(http_requests_total{namespace=\"image-gallery\"}[5m])"
                        legendFormat = "{{method}} {{handler}}"
                      }
                    ]
                  },
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "Request Duration (p95)"
                    type      = "graph"
                    gridPos   = { h = 8, w = 12, x = 12, y = 0 }
                    targets = [
                      {
                        expr = "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{namespace=\"image-gallery\"}[5m]))"
                        legendFormat = "{{handler}}"
                      }
                    ]
                  },
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "Image Uploads"
                    type      = "graph"
                    gridPos   = { h = 8, w = 12, x = 0, y = 8 }
                    targets = [
                      {
                        expr = "rate(image_uploads_total{namespace=\"image-gallery\"}[5m])"
                        legendFormat = "{{status}}"
                      }
                    ]
                  },
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "S3 Operation Duration"
                    type      = "graph"
                    gridPos   = { h = 8, w = 12, x = 12, y = 8 }
                    targets = [
                      {
                        expr = "histogram_quantile(0.95, rate(s3_operation_duration_seconds_bucket{namespace=\"image-gallery\"}[5m]))"
                        legendFormat = "{{operation}}"
                      }
                    ]
                  },
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "Application Uptime"
                    type      = "stat"
                    gridPos   = { h = 4, w = 6, x = 0, y = 16 }
                    targets = [
                      {
                        expr = "app_uptime_seconds{namespace=\"image-gallery\"}"
                      }
                    ]
                    options = {
                      reduceOptions = {
                        values = false
                        calcs  = ["lastNotNull"]
                      }
                    }
                    unit = "s"
                  },
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "S3 Connection Status"
                    type      = "stat"
                    gridPos   = { h = 4, w = 6, x = 6, y = 16 }
                    targets = [
                      {
                        expr = "health_check_s3_status{namespace=\"image-gallery\"}"
                      }
                    ]
                    options = {
                      reduceOptions = {
                        values = false
                        calcs  = ["lastNotNull"]
                      }
                    }
                  },
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "Images Stored"
                    type      = "stat"
                    gridPos   = { h = 4, w = 6, x = 12, y = 16 }
                    targets = [
                      {
                        expr = "images_stored_total{namespace=\"image-gallery\"}"
                      }
                    ]
                    options = {
                      reduceOptions = {
                        values = false
                        calcs  = ["lastNotNull"]
                      }
                    }
                  },
                  {
                    datasource = {
                      type = "prometheus"
                      uid  = "prometheus"
                    }
                    title     = "Error Rate"
                    type      = "stat"
                    gridPos   = { h = 4, w = 6, x = 18, y = 16 }
                    targets = [
                      {
                        expr = "rate(http_requests_total{namespace=\"image-gallery\",status=~\"5..\"}[5m])"
                      }
                    ]
                    options = {
                      reduceOptions = {
                        values = false
                        calcs  = ["lastNotNull"]
                      }
                    }
                  }
                ]
              })
            }
          }
        }
      }

      # Alert Manager
      alertmanager = {
        enabled = true
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                accessModes = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
        }
      }

      # Node Exporter
      nodeExporter = {
        enabled = true
      }

      # Kube State Metrics
      kubeStateMetrics = {
        enabled = true
      }
    })
  ]

  depends_on = [
    aws_eks_node_group.default
  ]

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-prometheus-stack"
    }
  )
}

#----------------------------------------------
# ServiceMonitor for Image Gallery App
#----------------------------------------------
# Note: ServiceMonitor will be created manually via kubectl or in application Helm chart
# Example command:
# kubectl apply -f - <<EOF
# apiVersion: monitoring.coreos.com/v1
# kind: ServiceMonitor
# metadata:
#   name: image-gallery
#   namespace: image-gallery
#   labels:
#     app: image-gallery
# spec:
#   selector:
#     matchLabels:
#       app.kubernetes.io/name: image-gallery
#   endpoints:
#   - port: http
#     path: /metrics
#     interval: 30s
# EOF
