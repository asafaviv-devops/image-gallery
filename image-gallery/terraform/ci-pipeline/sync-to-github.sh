#!/bin/bash
# sync-to-github.sh - Sync Terraform outputs to GitHub Secrets

set -e

echo "🔄 Syncing Terraform outputs to GitHub Secrets..."

# Get outputs from Terraform
ECR_REPO=$(terraform output -raw ecr_repository_name)
ECR_URL=$(terraform output -raw ecr_repository_url)
ROLE_ARN=$(terraform output -raw github_actions_role_arn)
AWS_REGION=$(terraform output -raw aws_region)
AWS_ACCOUNT=$(terraform output -raw aws_account_id)

# S3 bucket (if exists)
if terraform output s3_bucket_name &> /dev/null; then
  S3_BUCKET=$(terraform output -raw s3_bucket_name)
else
  S3_BUCKET=""
fi

# GitHub repo (get from terraform.tfvars)
GITHUB_ORG=$(grep github_org terraform.tfvars | cut -d'"' -f2)
GITHUB_REPO=$(grep github_repo terraform.tfvars | cut -d'"' -f2)

echo "Repository: $GITHUB_ORG/$GITHUB_REPO"
echo ""
echo "Values to sync:"
echo "  ECR_REPOSITORY: $ECR_REPO"
echo "  ECR_REPOSITORY_URL: $ECR_URL"
echo "  AWS_ROLE_ARN: $ROLE_ARN"
echo "  AWS_REGION: $AWS_REGION"
echo "  AWS_ACCOUNT_ID: $AWS_ACCOUNT"
if [ -n "$S3_BUCKET" ]; then
  echo "  S3_BUCKET_NAME: $S3_BUCKET"
fi
echo ""

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI not found. Install: https://cli.github.com/"
    echo ""
    echo "Or manually set these secrets in GitHub:"
    echo ""
    echo "https://github.com/$GITHUB_ORG/$GITHUB_REPO/settings/secrets/actions"
    echo ""
    echo "AWS_ROLE_ARN=$ROLE_ARN"
    echo "ECR_REPOSITORY=$ECR_REPO"
    echo "ECR_REPOSITORY_URL=$ECR_URL"
    echo "AWS_REGION=$AWS_REGION"
    echo "AWS_ACCOUNT_ID=$AWS_ACCOUNT"
    if [ -n "$S3_BUCKET" ]; then
      echo "S3_BUCKET_NAME=$S3_BUCKET"
    fi
    exit 1
fi

# Authenticate with GitHub (if needed)
if ! gh auth status &> /dev/null; then
    echo "🔐 Authenticating with GitHub..."
    gh auth login
fi

# Set secrets
echo "📝 Setting GitHub Secrets..."

gh secret set AWS_ROLE_ARN \
    --repo "$GITHUB_ORG/$GITHUB_REPO" \
    --body "$ROLE_ARN"

gh secret set ECR_REPOSITORY \
    --repo "$GITHUB_ORG/$GITHUB_REPO" \
    --body "$ECR_REPO"

gh secret set ECR_REPOSITORY_URL \
    --repo "$GITHUB_ORG/$GITHUB_REPO" \
    --body "$ECR_URL"

gh secret set AWS_REGION \
    --repo "$GITHUB_ORG/$GITHUB_REPO" \
    --body "$AWS_REGION"

gh secret set AWS_ACCOUNT_ID \
    --repo "$GITHUB_ORG/$GITHUB_REPO" \
    --body "$AWS_ACCOUNT"

if [ -n "$S3_BUCKET" ]; then
  gh secret set S3_BUCKET_NAME \
      --repo "$GITHUB_ORG/$GITHUB_REPO" \
      --body "$S3_BUCKET"
fi

echo ""
echo "✅ GitHub Secrets updated successfully!"
echo ""
echo "You can now use them in workflows:"
echo '  ${{ secrets.AWS_ROLE_ARN }}'
echo '  ${{ secrets.ECR_REPOSITORY }}'
echo '  ${{ secrets.AWS_REGION }}'
if [ -n "$S3_BUCKET" ]; then
  echo '  ${{ secrets.S3_BUCKET_NAME }}'
fi
