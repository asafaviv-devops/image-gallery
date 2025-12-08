#!/bin/bash
# setup-ci.sh - Quick setup script for CI pipeline

set -e

echo "🚀 Image Gallery CI Pipeline Setup"
echo "=================================="
echo ""

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform not found. Please install: https://www.terraform.io/downloads"
    exit 1
fi

if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install: https://aws.amazon.com/cli/"
    exit 1
fi

echo "✅ Terraform found: $(terraform version | head -1)"
echo "✅ AWS CLI found: $(aws --version)"
echo ""

# Check AWS credentials
echo "🔐 Checking AWS credentials..."
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ AWS credentials not configured. Run: aws configure"
    exit 1
fi

AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
echo "✅ AWS Account: $AWS_ACCOUNT"
echo ""

# Get user input
echo "📝 Configuration:"
echo ""

read -p "GitHub username or org [your-username]: " GITHUB_ORG
GITHUB_ORG=${GITHUB_ORG:-your-username}

read -p "GitHub repository name [image-gallery]: " GITHUB_REPO
GITHUB_REPO=${GITHUB_REPO:-image-gallery}

read -p "AWS Region [us-east-1]: " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

read -p "ECR Repository name [image-gallery]: " ECR_REPO
ECR_REPO=${ECR_REPO:-image-gallery}

echo ""
echo "Configuration:"
echo "  GitHub: $GITHUB_ORG/$GITHUB_REPO"
echo "  AWS Region: $AWS_REGION"
echo "  ECR Repository: $ECR_REPO"
echo ""

read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Create terraform.tfvars
echo ""
echo "📝 Creating terraform.tfvars..."
cat > terraform.tfvars <<EOF
aws_region          = "$AWS_REGION"
project_name        = "image-gallery"
github_org          = "$GITHUB_ORG"
github_repo         = "$GITHUB_REPO"
ecr_repository_name = "$ECR_REPO"
image_retention_count = 10

tags = {
  Project     = "image-gallery"
  ManagedBy   = "terraform"
  Environment = "production"
}
EOF

echo "✅ terraform.tfvars created"
echo ""

# Initialize Terraform
echo "🔧 Initializing Terraform..."
terraform init
echo ""

# Plan
echo "📊 Planning Terraform changes..."
terraform plan -out=tfplan
echo ""

# Confirm
read -p "Apply these changes? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted. Run 'terraform apply' manually when ready."
    exit 0
fi

# Apply
echo ""
echo "🚀 Applying Terraform..."
terraform apply tfplan
rm -f tfplan
echo ""

# Get outputs
echo "✅ Infrastructure created!"
echo ""
echo "📊 Outputs:"
echo "==========="
terraform output
echo ""

# Save role ARN
ROLE_ARN=$(terraform output -raw github_actions_role_arn)
ECR_URL=$(terraform output -raw ecr_repository_url)

echo "🔐 GitHub Secret Configuration:"
echo "==============================="
echo ""
echo "Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
echo ""
echo "Add this secret:"
echo "  Name:  AWS_ROLE_ARN"
echo "  Value: $ROLE_ARN"
echo ""

# Save to file
cat > setup-info.txt <<EOF
CI Pipeline Setup Complete
==========================

GitHub Repository: $GITHUB_ORG/$GITHUB_REPO
AWS Region: $AWS_REGION
AWS Account: $AWS_ACCOUNT

GitHub Actions Role ARN:
$ROLE_ARN

ECR Repository URL:
$ECR_URL

Next Steps:
1. Add GitHub Secret:
   - Go to: https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions
   - Name: AWS_ROLE_ARN
   - Value: $ROLE_ARN

2. Copy workflow file:
   cp ../../../github-workflows/ci.yml .github/workflows/

3. Commit and push:
   git add .github/workflows/ci.yml
   git commit -m "Add CI workflow"
   git push

4. Watch the workflow run:
   https://github.com/$GITHUB_ORG/$GITHUB_REPO/actions
EOF

echo "💾 Setup information saved to: setup-info.txt"
echo ""
echo "✅ Setup complete! Follow the next steps above."
