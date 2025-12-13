#----------------------------------------------
# CloudWatch Container Insights and Monitoring
#----------------------------------------------

locals {
  monitoring_namespace = "amazon-cloudwatch"
}

#----------------------------------------------
# CloudWatch Log Groups
#----------------------------------------------
# Log groups are managed by CloudWatch Observability Add-on
# The add-on creates log groups under /aws/containerinsights/{cluster-name}/

#----------------------------------------------
# IAM Policy for CloudWatch Agent
#----------------------------------------------

resource "aws_iam_role_policy_attachment" "node_cloudwatch_agent" {
  count = var.enable_monitoring ? 1 : 0

  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "node_cloudwatch_logs" {
  count = var.enable_monitoring ? 1 : 0

  role       = aws_iam_role.node.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

#----------------------------------------------
# AWS CloudWatch Observability Add-on
#----------------------------------------------

resource "aws_eks_addon" "cloudwatch_observability" {
  count = var.enable_monitoring ? 1 : 0

  cluster_name = aws_eks_cluster.this.name
  addon_name   = "amazon-cloudwatch-observability"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-cloudwatch-observability"
    }
  )

  depends_on = [
    aws_eks_node_group.default,
    aws_iam_role_policy_attachment.node_cloudwatch_agent,
    aws_iam_role_policy_attachment.node_cloudwatch_logs
  ]
}

#----------------------------------------------
# SNS Topic for Alerts
#----------------------------------------------

resource "aws_sns_topic" "alerts" {
  count = var.enable_monitoring && var.alert_email != "" ? 1 : 0

  name = "${local.prefix}-eks-alerts"

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-eks-alerts"
    }
  )
}

resource "aws_sns_topic_subscription" "email" {
  count = var.enable_monitoring && var.alert_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alerts[0].arn
  protocol  = "email"
  endpoint  = var.alert_email
}

#----------------------------------------------
# CloudWatch Alarms
#----------------------------------------------

# High CPU Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${local.prefix}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_cpu_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alert when CPU utilization exceeds 80%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_eks_cluster.this.name
  }

  alarm_actions = var.alert_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-high-cpu-alarm"
    }
  )
}

# High Memory Utilization Alarm
resource "aws_cloudwatch_metric_alarm" "high_memory" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${local.prefix}-high-memory-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "node_memory_utilization"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Average"
  threshold           = 85
  alarm_description   = "Alert when memory utilization exceeds 85%"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_eks_cluster.this.name
  }

  alarm_actions = var.alert_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-high-memory-alarm"
    }
  )
}

# Pod Restart Alarm
resource "aws_cloudwatch_metric_alarm" "pod_restarts" {
  count = var.enable_monitoring ? 1 : 0

  alarm_name          = "${local.prefix}-pod-restart-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "pod_number_of_container_restarts"
  namespace           = "ContainerInsights"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Alert when pod restart rate is high"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ClusterName = aws_eks_cluster.this.name
  }

  alarm_actions = var.alert_email != "" ? [aws_sns_topic.alerts[0].arn] : []

  tags = merge(
    local.common_tags,
    {
      Name = "${local.prefix}-pod-restart-alarm"
    }
  )
}

#----------------------------------------------
# CloudWatch Dashboard
#----------------------------------------------

resource "aws_cloudwatch_dashboard" "eks" {
  count = var.enable_monitoring ? 1 : 0

  dashboard_name = "${local.prefix}-eks-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "node_cpu_utilization", { stat = "Average" }],
            [".", "node_cpu_usage_total", { stat = "Average" }]
          ]
          period  = 300
          stat    = "Average"
          region  = "us-east-1"
          title   = "CPU Utilization"
          yAxis   = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [
              {
                value = 80
                label = "High CPU Threshold"
                fill  = "above"
              }
            ]
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "node_memory_utilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Memory Utilization"
          yAxis  = { left = { min = 0, max = 100 } }
          annotations = {
            horizontal = [
              {
                value = 85
                label = "High Memory Threshold"
                fill  = "above"
              }
            ]
          }
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "pod_cpu_utilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Pod CPU Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "pod_memory_utilization", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Pod Memory Utilization"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "pod_number_of_container_restarts", { stat = "Sum" }]
          ]
          period = 300
          stat   = "Sum"
          region = "us-east-1"
          title  = "Pod Restarts"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "cluster_failed_node_count", { stat = "Average" }],
            [".", "cluster_node_count", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Cluster Nodes"
        }
      },
      {
        type = "metric"
        properties = {
          metrics = [
            ["ContainerInsights", "pod_network_rx_bytes", { stat = "Average" }],
            [".", "pod_network_tx_bytes", { stat = "Average" }]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Network Traffic (RX/TX)"
        }
      },
      {
        type = "log"
        properties = {
          query   = <<-EOT
            SOURCE '/aws/containerinsights/${aws_eks_cluster.this.name}/application'
            | fields @timestamp, @message
            | filter @message like /ERROR/ or @message like /error/
            | sort @timestamp desc
            | limit 20
          EOT
          region  = "us-east-1"
          title   = "Recent Application Errors"
          stacked = false
        }
      }
    ]
  })
}
