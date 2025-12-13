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

### Option A: Automated Setup (Recommended)

Use the provided setup scripts for a guided installation:

#### 1. Bootstrap Terraform State Backend

```bash
cd terraform/ci-pipeline/bootstrap
chmod +x setup-bootstrap.sh
./setup-bootstrap.sh
```

This creates:
- S3 bucket for Terraform state
- DynamoDB table for state locking

#### 2. Setup CI/CD Pipeline

```bash
cd ../  # Back to ci-pipeline directory
chmod +x setup-ci.sh
./setup-ci.sh
```

This will:
- ✅ Check prerequisites (Terraform, AWS CLI)
- ✅ Verify AWS credentials
- ✅ Prompt for configuration (GitHub repo, ECR name, etc.)
- ✅ Create ECR repository
- ✅ Create GitHub Actions OIDC role
- ✅ Display GitHub Secrets to configure

#### 3. Sync Secrets to GitHub

```bash
chmod +x sync-to-github.sh
./sync-to-github.sh
```

This automatically sets GitHub Secrets:
- `AWS_ROLE_ARN`
- `ECR_REPOSITORY`
- `AWS_REGION`
- `AWS_ACCOUNT_ID`

**Or manually add secrets** at: `https://github.com/YOUR_ORG/YOUR_REPO/settings/secrets/actions`

### Option B: Manual Setup

#### 1. Clone Repository

```bash
git clone https://github.com/asafaviv-devops/image-gallery.git
cd image-gallery
```

#### 2. Configure Terraform

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
│   ├── ci-pipeline/                  # CI/CD Infrastructure
│   │   ├── setup-ci.sh               # 🚀 Automated CI setup script
│   │   ├── sync-to-github.sh         # 🔄 Sync secrets to GitHub
│   │   ├── bootstrap/
│   │   │   └── setup-bootstrap.sh    # 📦 Setup Terraform backend
│   │   ├── main.tf                   # ECR, IAM roles for GitHub Actions
│   │   ├── variables.tf
│   │   └── outputs.tf
│   │
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

The project includes a complete CI/CD pipeline using GitHub Actions with two workflows:

### CI Workflow (`ci.yml`) - Build & Security

**Location:** `.github/workflows/ci.yml`

**Triggers:**
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop`
- Changes to: `app/**`, `Dockerfile`, `requirements.txt`
- Manual trigger (`workflow_dispatch`)

**Steps:**

1. **Checkout Code**
   - Uses: `actions/checkout@v4`

2. **AWS Authentication (OIDC)**
   - Uses: `aws-actions/configure-aws-credentials@v4`
   - Assumes IAM role via OIDC (no static credentials!)
   - Verifies AWS identity

3. **Login to Amazon ECR**
   - Uses: `aws-actions/amazon-ecr-login@v2`

4. **Build Docker Image**
   - Uses Docker Buildx for multi-platform builds
   - Implements layer caching via GitHub Actions cache
   - Platform: `linux/amd64`

5. **Tag Image**
   - `latest` (for default branch)
   - `{branch}-{sha}` (for feature branches)
   - `pr-{number}` (for pull requests)

6. **Push to ECR**
   - Multi-tag push to Amazon ECR

7. **Security Scan**
   - Uses: `aquasecurity/trivy-action`
   - Scans for vulnerabilities
   - Uploads results to GitHub Security tab (SARIF format)
   - Continues on error (doesn't block deployment)

8. **Build Summary**
   - Displays build info in GitHub Actions summary

**Example Workflow Run:**
```
✅ Build Docker image → ✅ Push to ECR → ✅ Security scan → ✅ Summary
```

---

### CD Workflow (`cd-helm.yml`) - Deploy to EKS

**Location:** `.github/workflows/cd-helm.yml`

**Triggers:**
- Automatically after successful CI workflow completion
- Manual trigger with environment selection (`dev`, `staging`, `prod`)

**Environment Mapping:**
- `main` branch → `prod` environment
- `develop` branch → `dev` environment
- Manual trigger → user-selected environment

**Steps:**

1. **Determine Environment**
   - Automatically selects based on branch
   - Or uses manual input from `workflow_dispatch`

2. **AWS Authentication (OIDC)**
   - Assumes role for EKS access

3. **Verify Cluster Exists**
   - Checks cluster: `image-gallery-{env}-eks-cluster`
   - Fails if cluster not found

4. **Update kubeconfig**
   - Configures kubectl for target cluster
   - Verifies connection with `kubectl cluster-info`

5. **Install Helm**
   - Uses: `azure/setup-helm@v3`
   - Version: `latest`

6. **Deploy with Helm**
   ```bash
   helm upgrade --install image-gallery ./helm/image-gallery \
     --namespace image-gallery \
     --values values.yaml \
     --values values-{env}.yaml \
     --set image.tag={TAG} \
     --set config.s3Bucket={S3_BUCKET} \
     --set serviceAccount.annotations."eks.amazonaws.com/role-arn"={IRSA_ROLE_ARN} \
     --wait
   ```

7. **Verify Deployment**
   - Checks deployment status
   - Counts ready pods vs total pods
   - Fails if any pods are not ready

8. **Get Helm Release Info**
   - Displays Helm release status
   - Shows deployed resources

9. **Deployment Summary**
   - Environment, image tag, cluster info
   - Helm release details
   - Pod status
   - Service endpoints

**Example Workflow Run:**
```
CI Complete → ✅ Select env → ✅ Connect to EKS → ✅ Helm deploy → ✅ Verify → ✅ Summary
```

---

### Required GitHub Secrets

Configure in **Settings → Secrets and variables → Actions**:

| Secret | Description | Example | How to Get |
|--------|-------------|---------|------------|
| `AWS_ROLE_ARN` | IAM role for GitHub OIDC | `arn:aws:iam::123456789012:role/...` | Terraform output from CI pipeline setup |
| `ECR_REPOSITORY` | ECR repository name | `image-gallery` | Terraform output |
| `ECR_REPOSITORY_URL` | Full ECR URL | `123456789012.dkr.ecr.us-east-1.amazonaws.com/image-gallery` | Terraform output |
| `AWS_REGION` | AWS region | `us-east-1` | From your AWS config |
| `AWS_ACCOUNT_ID` | AWS account ID | `123456789012` | `aws sts get-caller-identity` |
| `S3_BUCKET_NAME` | S3 bucket for images | `image-gallery-dev-images` | Terraform output |
| `IRSA_ROLE_ARN` | IRSA role for pods | `arn:aws:iam::123456789012:role/...` | Terraform output from EKS module |

**Quick Setup with Script:**
```bash
cd terraform/ci-pipeline
./sync-to-github.sh
```

This automatically syncs all secrets to GitHub!

---

### Manual Workflow Triggers

#### Trigger CI Manually:
1. Go to **Actions** → **CI - Build and Push to ECR**
2. Click **Run workflow**
3. Select branch
4. Click **Run workflow**

#### Trigger CD Manually:
1. Go to **Actions** → **CD - Deploy to EKS**
2. Click **Run workflow**
3. Select:
   - **Environment**: `dev`, `staging`, or `prod`
   - **Image tag**: e.g., `latest`, `main-abc1234`
4. Click **Run workflow**

---

### Pipeline Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│  Developer pushes to main/develop                       │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  CI Workflow (ci.yml)                                   │
│  ├── Checkout code                                      │
│  ├── AWS auth (OIDC)                                    │
│  ├── Build Docker image                                 │
│  ├── Push to ECR                                        │
│  └── Security scan (Trivy)                              │
└────────────────┬────────────────────────────────────────┘
                 │
                 │ (on success)
                 ▼
┌─────────────────────────────────────────────────────────┐
│  CD Workflow (cd-helm.yml)                              │
│  ├── Determine environment (main=prod, develop=dev)    │
│  ├── AWS auth (OIDC)                                    │
│  ├── Update kubeconfig                                  │
│  ├── Helm upgrade --install                             │
│  ├── Verify deployment                                  │
│  └── Display summary                                    │
└────────────────┬────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────┐
│  Application running in EKS                             │
│  - Pods: 2 replicas                                     │
│  - Service: ClusterIP                                   │
│  - Metrics: Prometheus scraping                         │
└─────────────────────────────────────────────────────────┘
```

---

### Best Practices Implemented

✅ **OIDC Authentication** - No long-lived AWS credentials
✅ **Multi-stage builds** - Optimized Docker images
✅ **Layer caching** - Faster builds with GitHub Actions cache
✅ **Security scanning** - Trivy vulnerability detection
✅ **SARIF integration** - Security results in GitHub Security tab
✅ **Automated deployment** - Deploy on successful CI
✅ **Environment separation** - dev/staging/prod isolation
✅ **Health checks** - Verify pods are ready before completing
✅ **Helm rollback** - Automatic rollback on deployment failure
✅ **Detailed summaries** - Rich deployment info in GitHub UI

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
