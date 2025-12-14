#!/bin/bash
# setup-bootstrap.sh
# Automated bootstrap setup script

set -e

echo "🚀 Terraform Bootstrap Setup"
echo "============================"
echo ""

# Check if already in bootstrap directory
if [ ! -f "main.tf" ]; then
    if [ -d "terraform/bootstrap" ]; then
        cd terraform/bootstrap
    else
        echo "❌ Error: Run this from project root or terraform/bootstrap/"
        exit 1
    fi
fi

echo "📍 Working directory: $(pwd)"
echo ""

# Check AWS credentials
echo "🔑 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured!"
    echo "Run: aws configure"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION=$(aws configure get region || echo "us-east-1")

echo "✅ AWS Account: $ACCOUNT_ID"
echo "✅ AWS Region: $REGION"
echo ""

# Initialize Terraform
echo "📦 Initializing Terraform..."
terraform init
echo ""

# Plan
echo "📋 Planning bootstrap resources..."
terraform plan -out=tfplan
echo ""

# Confirm
read -p "🤔 Apply these changes? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "❌ Aborted"
    exit 0
fi

# Apply
echo ""
echo "🚀 Creating state bucket and lock table..."
terraform apply tfplan
echo ""

# Get outputs
BUCKET=$(terraform output -raw state_bucket_name)

echo ""
echo "✅ Bootstrap Complete!"
echo "===================="
echo ""
echo "📦 State Bucket: $BUCKET"
echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Update backend configuration in main Terraform:"
echo ""
echo "   cd ../ci-pipeline/"
echo "   nano backend.tf"
echo ""
echo "   Update with:"
echo "   bucket = \"$BUCKET\""
echo ""
echo "2. Initialize main Terraform:"
echo ""
echo "   terraform init"
echo "   terraform apply"
echo ""
echo "⚠️  IMPORTANT: Backup bootstrap state file!"
echo "   terraform/bootstrap/terraform.tfstate"
echo ""
