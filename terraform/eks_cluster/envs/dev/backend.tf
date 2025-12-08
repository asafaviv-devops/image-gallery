terraform {
  backend "s3" {
    bucket         = "my-terraform-state-184890426414"   
    key            = "envs/dev/terraform.tfstate"       
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}

