# Terraform Bootstrap

## Purpose

This directory creates the S3 bucket and DynamoDB table needed for Terraform remote state.

**Run this ONCE before using the main Terraform configuration.**

---

## What it creates:

1. **S3 Bucket**: `image-gallery-tfstate-<account-id>`
   - Versioning enabled
   - Public access blocked
   - Encryption enabled
   - Lifecycle: keep old versions for 90 days

2. **DynamoDB Table**: `image-gallery-tfstate-lock`
   - For state locking (prevents concurrent modifications)
   - Pay-per-request billing

---

## Usage:

### 1. Run Bootstrap (once):

```bash
cd terraform/bootstrap/

# Initialize
terraform init

# Review plan
terraform plan

# Create state bucket
terraform apply

# Save outputs
terraform output state_bucket_name
# Output: image-gallery-tfstate-184890426414
```

---

### 2. Configure Backend in Main Terraform:

Copy the output values to `terraform/ci-pipeline/backend.tf`:

```bash
# Get bucket name
BUCKET=$(terraform output -raw state_bucket_name)
TABLE=$(terraform output -raw dynamodb_table_name)

echo "bucket = \"$BUCKET\""
echo "dynamodb_table = \"$TABLE\""
```

Update `terraform/ci-pipeline/backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket         = "image-gallery-tfstate-184890426414"  # from output
    key            = "ci-pipeline/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "image-gallery-tfstate-lock"          # from output
  }
}
```

---

### 3. Initialize Main Terraform:

```bash
cd ../ci-pipeline/

# Initialize with backend
terraform init

# Now state is stored in S3!
terraform apply
```

---

## State Management:

### Bootstrap state:
- Stored **locally** in `terraform/bootstrap/terraform.tfstate`
- **DO NOT delete this file!**
- Commit to git or backup securely

### Main Terraform state:
- Stored **remotely** in S3: `s3://image-gallery-tfstate-<account-id>/ci-pipeline/terraform.tfstate`
- Versioned and encrypted
- Shared across team/CI

---

## Important Notes:

⚠️ **Never delete the bootstrap state file!**
   - If lost, you'll need to import resources

⚠️ **The S3 bucket name must be globally unique**
   - Uses account ID to ensure uniqueness

⚠️ **Run bootstrap only once per AWS account**
   - Multiple projects can share the same state bucket (different keys)

---

## Cleanup:

If you need to destroy everything:

```bash
# 1. Destroy main resources
cd terraform/ci-pipeline/
terraform destroy

# 2. Destroy bootstrap (last!)
cd ../bootstrap/
terraform destroy
```

**Warning:** Destroying the state bucket will delete all Terraform state!

---

## Troubleshooting:

### Bucket already exists:
```bash
# Import existing bucket
terraform import aws_s3_bucket.terraform_state image-gallery-tfstate-184890426414
```

### DynamoDB table exists:
```bash
terraform import aws_dynamodb_table.terraform_state_lock image-gallery-tfstate-lock
```

---

## Multi-Environment:

Use different `key` for each environment:

```hcl
# Dev
key = "dev/ci-pipeline/terraform.tfstate"

# Staging
key = "staging/ci-pipeline/terraform.tfstate"

# Prod
key = "prod/ci-pipeline/terraform.tfstate"
```

Same bucket, different state files!
