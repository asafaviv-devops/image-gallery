resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-184890426414"

  tags = {
    Name      = "terraform-state"
    ManagedBy = "terraform"
    Purpose   = "terraform-backend"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state_versioning" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state_sse" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


output "backend_bucket_name" {
  value = aws_s3_bucket.terraform_state.bucket
}


