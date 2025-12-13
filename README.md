# Image Gallery - Production-Ready AWS EKS Deployment

A complete DevOps implementation of a cloud-native image gallery application on AWS EKS with comprehensive monitoring, CI/CD, and infrastructure as code.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Project Structure](#project-structure)
- [Infrastructure Setup](#infrastructure-setup)
- [Application Deployment](#application-deployment)
- [Monitoring & Observability](#monitoring--observability)
- [CI/CD Pipeline](#cicd-pipeline)
- [Accessing Services](#accessing-services)
- [Troubleshooting](#troubleshooting)

## 🎯 Overview

This project demonstrates enterprise-grade DevOps practices for deploying a FastAPI image gallery application on AWS EKS.

### Key Features

**Application:**
- 📤 Upload images to S3 with automatic thumbnail generation
- 🖼️ Beautiful gallery interface with responsive design
- ✏️ Edit image metadata (title, description, tags)
- 🗑️ Delete images from S3
- 📊 Prometheus metrics for monitoring
- 🏥 Health checks and readiness probes

**Infrastructure:**
- ☁️ AWS EKS with multi-AZ high availability
- 🏗️ Infrastructure as Code using Terraform
- 🐳 Containerized application with Docker
- ⎈ Kubernetes orchestration with Helm charts
- 📊 Dual monitoring: CloudWatch + Prometheus/Grafana
- 🔔 Email alerts via SNS for critical metrics
- 🔄 GitHub Actions CI/CD pipeline
- 🔐 IRSA (IAM Roles for Service Accounts) for security

## 🏗️ Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    AWS Cloud (us-east-1)                │
│                                                         │
│  ┌──────────────────────────────────────────────────┐  │
│  │           VPC (10.0.0.0/16)                      │  │
│  │                                                  │  │
│  │  ┌─────────────┐         ┌─────────────┐        │  │
│  │  │   Public    │         │   Public    │        │  │
│  │  │  Subnet 1   │         │  Subnet 2   │        │  │
│  │  │ (NAT GW)    │         │ (NAT GW)    │        │  │
│  │  └─────────────┘         └─────────────┘        │  │
│  │         │                       │               │  │
│  │  ┌──────▼───────────────────────▼──────┐        │  │
│  │  │      Private Subnets (EKS)          │        │  │
│  │  │                                     │        │  │
│  │  │  ┌───────────────────────────────┐  │        │  │
│  │  │  │   image-gallery namespace    │  │        │  │
│  │  │  │   - Deployment (2 replicas)  │  │        │  │
│  │  │  │   - ServiceMonitor           │  │        │  │
│  │  │  └───────────────────────────────┘  │        │  │
│  │  │                                     │        │  │
│  │  │  ┌───────────────────────────────┐  │        │  │
│  │  │  │   monitoring namespace       │  │        │  │
│  │  │  │   - Prometheus               │  │        │  │
│  │  │  │   - Grafana (LoadBalancer)   │  │        │  │
│  │  │  │   - AlertManager             │  │        │  │
│  │  │  └───────────────────────────────┘  │        │  │
│  │  └─────────────────────────────────────┘        │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐ │
│  │   ECR    │  │   S3     │  │   CloudWatch         │ │
│  │ (Images) │  │ (Data)   │  │   - Dashboard        │ │
│  │          │  │          │  │   - Alarms           │ │
│  └──────────┘  └──────────┘  │   - SNS Alerts       │ │
│                               └──────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

### Components

| Component | Purpose | Technology |
|-----------|---------|------------|
| **Application** | Image gallery web service | FastAPI, Python |
| **Container Registry** | Docker image storage | AWS ECR |
| **Object Storage** | Image file storage | AWS S3 |
| **Orchestration** | Container management | AWS EKS (Kubernetes) |
| **Infrastructure** | IaC provisioning | Terraform |
| **Monitoring** | Metrics & logs | CloudWatch, Prometheus, Grafana |
| **Alerting** | Critical notifications | SNS, AlertManager |
| **CI/CD** | Automated deployment | GitHub Actions |

## ✅ Prerequisites

### Required Tools

| Tool | Version | Installation |
|------|---------|--------------|
| AWS CLI | v2.x | https://aws.amazon.com/cli/ |
| Terraform | v1.5+ | https://terraform.io/downloads |
| kubectl | v1.27+ | https://kubernetes.io/docs/tasks/tools/ |
| Helm | v3.9+ | https://helm.sh/docs/intro/install/ |
| Docker | Latest | https://docs.docker.com/get-docker/ |

### Verify Installation

```bash
aws --version
terraform version
kubectl version --client
helm version
docker --version
```

### AWS Requirements

- AWS Account with administrative access
- IAM User/Role with permissions for:
  - EKS, EC2, VPC, IAM, S3, ECR
  - CloudWatch, SNS, ALB
- Configured AWS credentials:
  ```bash
  aws configure
  # OR
  export AWS_PROFILE=your-profile
  ```

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone https://github.com/asafaviv-devops/image-gallery.git
cd image-gallery
```

### 2. Configure Terraform

```bash
cd terraform/eks_cluster/envs/dev

# Edit terraform.tfvars
nano terraform.tfvars
```

**Update these values:**
```hcl
alert_email = "your-email@example.com"  # For CloudWatch alerts
admin_role_arn = "arn:aws:iam::YOUR_ACCOUNT:user/YOUR_USER"
```

### 3. Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review plan
terraform plan

# Apply (takes ~15-20 minutes)
terraform apply
```

### 4. Configure kubectl

```bash
# Get command from Terraform output
terraform output kubectl_config_command

# Run it (example):
aws eks update-kubeconfig --region us-east-1 --name image-gallery-dev-eks

# Verify
kubectl get nodes
```

### 5. Deploy Application

```bash
cd ~/image-gallery

helm upgrade --install image-gallery helm/image-gallery \
  --namespace image-gallery \
  --create-namespace \
  -f helm/image-gallery/values.yaml
```

### 6. Verify Deployment

```bash
# Check all pods are running
kubectl get pods -n image-gallery
kubectl get pods -n monitoring

# Get Grafana URL
kubectl get svc -n monitoring kube-prometheus-stack-grafana
```

### 7. Confirm Email Subscription

Check your email for AWS SNS subscription confirmation and click **Confirm subscription**.

## 📁 Project Structure

```
image-gallery/
│
├── app/                              # Application code
│   ├── main.py                       # FastAPI application
│   ├── requirements.txt              # Python dependencies
│   └── Dockerfile                    # Container image
│
├── helm/
│   └── image-gallery/                # Kubernetes Helm chart
│       ├── Chart.yaml
│       ├── values.yaml               # Configuration
│       └── templates/
│           ├── deployment.yaml       # App deployment
│           ├── service.yaml          # K8s service
│           ├── serviceaccount.yaml   # IRSA
│           ├── configmap.yaml        # Config
│           └── servicemonitor.yaml   # Prometheus metrics
│
├── terraform/
│   └── eks_cluster/
│       ├── modules/
│       │   ├── network/              # VPC, Subnets, NAT
│       │   │   ├── main.tf
│       │   │   ├── variables.tf
│       │   │   └── outputs.tf
│       │   │
│       │   └── eks/                  # EKS cluster & monitoring
│       │       ├── main.tf           # EKS cluster
│       │       ├── node_group.tf     # Worker nodes
│       │       ├── addons.tf         # EKS add-ons
│       │       ├── irsa.tf           # IAM roles
│       │       ├── monitoring.tf     # CloudWatch
│       │       ├── prometheus.tf     # Prometheus/Grafana
│       │       ├── variables.tf
│       │       └── outputs.tf
│       │
│       └── envs/
│           ├── dev/                  # Dev environment
│           │   ├── main.tf
│           │   ├── variables.tf
│           │   └── terraform.tfvars
│           ├── staging/              # Staging environment
│           └── prod/                 # Production environment
│
├── .github/
│   └── workflows/
│       ├── ci.yml                    # Build, test, scan
│       └── cd.yml                    # Deploy to EKS
│
└── README.md                         # This file
```

## 🏗️ Infrastructure Setup

### Network Module

Creates a production-ready VPC with:
- **VPC**: Custom CIDR (10.0.0.0/16)
- **Public Subnets**: 2 AZs for NAT Gateways
- **Private Subnets**: 2 AZs for EKS nodes
- **NAT Gateways**: High availability (one per AZ)
- **Route Tables**: Proper routing for public/private subnets

### EKS Module

Provisions:
- **EKS Cluster**: Kubernetes v1.27+
- **Managed Node Group**: Auto-scaling EC2 instances
- **OIDC Provider**: For IRSA
- **Add-ons**:
  - VPC CNI (networking)
  - CoreDNS (DNS)
  - kube-proxy (networking)
  - CloudWatch Observability (logs/metrics)
  - AWS Load Balancer Controller (optional)

### Monitoring Stack

**CloudWatch Container Insights:**
- Cluster metrics (CPU, Memory, Network)
- Pod metrics
- Custom dashboard
- Alarms:
  - High CPU (>80%)
  - High Memory (>85%)
  - Pod Restarts (>5 in 5min)
- SNS email notifications

**Prometheus/Grafana:**
- Prometheus (time-series DB)
- Grafana (visualization) - LoadBalancer
- AlertManager (notifications)
- Pre-configured "Image Gallery" dashboard

### Environment Comparison

| Resource | Dev | Staging | Prod |
|----------|-----|---------|------|
| Instance Type | t3.medium | t3.large | t3.xlarge |
| Node Count | 1-2 | 2-3 | 3-6 |
| App Replicas | 2 | 2 | 3 |
| Prometheus Retention | 15 days | 15 days | 30 days |

## 📦 Application Deployment

### Helm Chart Configuration

Key configurations in `helm/image-gallery/values.yaml`:

```yaml
# Container image
image:
  repository: 184890426414.dkr.ecr.us-east-1.amazonaws.com/image-gallery
  tag: latest
  pullPolicy: Always

# Replicas
replicaCount: 2

# Application config
config:
  awsRegion: us-east-1
  s3Bucket: image-gallery-dev-images
  logLevel: INFO
  maxUploadSize: "10485760"  # 10MB

# Prometheus metrics
metrics:
  enabled: true
  port: http
  path: /metrics
  interval: 30s
```

### Deploy to Different Environments

```bash
# Development
helm upgrade --install image-gallery helm/image-gallery \
  --namespace image-gallery \
  --set config.s3Bucket=image-gallery-dev-images

# Staging
helm upgrade --install image-gallery helm/image-gallery \
  --namespace image-gallery \
  --set config.s3Bucket=image-gallery-staging-images

# Production
helm upgrade --install image-gallery helm/image-gallery \
  --namespace image-gallery \
  --set config.s3Bucket=image-gallery-prod-images \
  --set replicaCount=3
```

## 📊 Monitoring & Observability

### CloudWatch Dashboard

Access via Terraform output:
```bash
terraform output cloudwatch_dashboard_url
```

**Widgets:**
- Node CPU/Memory Utilization
- Pod CPU/Memory Utilization
- Network Traffic (RX/TX)
- Cluster Node Count
- Pod Restart Count
- Recent Application Errors

### Grafana Dashboards

**Get Grafana URL:**
```bash
# From Terraform
$(terraform output -raw grafana_service_command)

# OR directly
kubectl get svc -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

**Login:**
- Username: `admin`
- Password: `admin` (change in production!)

**Pre-configured Dashboards:**
1. **Image Gallery Application Metrics**
   - Request Rate
   - Request Duration (p95)
   - Image Uploads
   - S3 Operation Duration
   - Application Uptime
   - Images Stored
   - Error Rate

2. **Kubernetes Cluster** (from kube-prometheus-stack)
   - Node metrics
   - Pod metrics
   - Deployments
   - StatefulSets

### Prometheus Targets

Verify metrics collection:
```bash
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
```

Open http://localhost:9090/targets

Expected targets:
- ✅ kubernetes-apiservers
- ✅ kubernetes-nodes
- ✅ kubernetes-pods
- ✅ image-gallery (ServiceMonitor)

### CloudWatch Alarms

Email alerts sent for:
1. **HighCPUUtilization**: CPU > 80% for 10 minutes
2. **HighMemoryUtilization**: Memory > 85% for 10 minutes
3. **PodRestarts**: > 5 restarts in 5 minutes

## 🔄 CI/CD Pipeline

### GitHub Actions Workflows

**CI Pipeline** (`.github/workflows/ci.yml`)
- Triggered on: Push to any branch
- Steps:
  1. Checkout code
  2. Build Docker image
  3. Security scan (Trivy)
  4. Run tests
  5. Push to ECR

**CD Pipeline** (`.github/workflows/cd.yml`)
- Triggered on: Push to `main`
- Steps:
  1. Configure AWS credentials (OIDC)
  2. Login to ECR
  3. Update kubeconfig
  4. Deploy via Helm
  5. Verify deployment

### Required GitHub Secrets

Configure in **Settings → Secrets → Actions**:

| Secret | Description |
|--------|-------------|
| `AWS_ROLE_ARN` | GitHub Actions OIDC role ARN |
| `ECR_REPOSITORY` | ECR repository URL |
| `EKS_CLUSTER_NAME` | EKS cluster name |
| `AWS_REGION` | AWS region (us-east-1) |

## 🔑 Accessing Services

### View All Terraform Outputs

```bash
cd terraform/eks_cluster/envs/dev
terraform output
```

### Important Outputs

```bash
# Cluster name
terraform output cluster_name

# kubectl configuration command
terraform output kubectl_config_command

# CloudWatch Dashboard URL
terraform output cloudwatch_dashboard_url

# Grafana access command
terraform output grafana_service_command

# Monitoring namespace
terraform output monitoring_namespace
```

### Access Grafana

```bash
# Get URL
GRAFANA_URL=$(kubectl get svc -n monitoring kube-prometheus-stack-grafana \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

echo "Grafana: http://$GRAFANA_URL"
```

### Access Application

```bash
# Get application service
kubectl get svc -n image-gallery

# Port-forward for local testing
kubectl port-forward -n image-gallery svc/image-gallery 8080:80

# Access at http://localhost:8080
```

## 🐛 Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n image-gallery

# Describe pod
kubectl describe pod <pod-name> -n image-gallery

# View logs
kubectl logs <pod-name> -n image-gallery

# Common issues:
# - ImagePullBackOff: Check ECR permissions
# - CrashLoopBackOff: Check application logs
# - Pending: Check node capacity (kubectl describe nodes)
```

### Grafana Not Accessible

```bash
# Check Grafana service
kubectl get svc -n monitoring kube-prometheus-stack-grafana

# Should show LoadBalancer with EXTERNAL-IP

# Check Grafana pod logs
kubectl logs -n monitoring deployment/kube-prometheus-stack-grafana
```

### Prometheus Not Scraping

```bash
# Verify ServiceMonitor exists
kubectl get servicemonitor -n image-gallery

# Check Prometheus targets
kubectl port-forward -n monitoring svc/kube-prometheus-stack-prometheus 9090:9090
# Open http://localhost:9090/targets

# Verify metrics.enabled in Helm values
helm get values image-gallery -n image-gallery | grep -A5 metrics
```

### CloudWatch Dashboard Shows "No Data"

**Verify CloudWatch Agent:**
```bash
kubectl get pods -n amazon-cloudwatch

# Should see:
# - cloudwatch-agent-*
# - fluent-bit-*
```

**Check metric dimensions:**
```bash
# Metrics should include ClusterName dimension
aws cloudwatch get-metric-statistics \
  --namespace ContainerInsights \
  --metric-name node_cpu_utilization \
  --dimensions Name=ClusterName,Value=image-gallery-dev-eks \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average
```

### Terraform Issues

```bash
# State lock issue
terraform force-unlock <lock-id>

# Refresh state
terraform refresh

# Import existing resource
terraform import <resource_type>.<name> <resource_id>
```

## 📈 Scaling

### Manual Scaling

```bash
# Scale application
kubectl scale deployment image-gallery -n image-gallery --replicas=5

# Scale via Helm
helm upgrade image-gallery helm/image-gallery \
  --set replicaCount=5
```

### Auto-scaling (Future Enhancement)

```yaml
# In values.yaml
autoscaling:
  enabled: true
  minReplicas: 2
  maxReplicas: 10
  targetCPUUtilizationPercentage: 80
```

## 🔐 Security Best Practices

- ✅ IRSA for AWS permissions (no hardcoded credentials)
- ✅ Private subnets for worker nodes
- ✅ Security groups with minimal access
- ✅ Container image scanning (Trivy)
- ✅ Non-root containers
- ✅ Read-only root filesystem
- ✅ Dropped capabilities
- ✅ Resource limits enforced

## 📚 Additional Resources

- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)

## 📝 API Documentation

When application is running, access Swagger UI:
- http://localhost:8080/docs (via port-forward)

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Gallery web interface |
| GET | `/health` | Health check |
| GET | `/metrics` | Prometheus metrics |
| GET | `/api/images` | List all images |
| POST | `/api/images` | Upload image |
| PUT | `/api/images/{id}` | Update metadata |
| DELETE | `/api/images/{id}` | Delete image |

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📧 Contact

**Author:** Asaf Aviv
**Email:** asaf.aviv21@gmail.com
**GitHub:** asafaviv-devops

## 📄 License

MIT License - see LICENSE file for details

---

**Built with ❤️ for DevOps Excellence**
