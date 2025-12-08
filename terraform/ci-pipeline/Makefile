# Makefile for CI Pipeline Terraform

.PHONY: help init plan apply destroy clean outputs

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

init: ## Initialize Terraform
	terraform init

validate: ## Validate Terraform configuration
	terraform validate

plan: ## Plan Terraform changes
	terraform plan

apply: ## Apply Terraform changes
	terraform apply

apply-auto: ## Apply Terraform changes without confirmation
	terraform apply -auto-approve

destroy: ## Destroy Terraform resources
	terraform destroy

destroy-auto: ## Destroy Terraform resources without confirmation
	terraform destroy -auto-approve

outputs: ## Show Terraform outputs
	terraform output

outputs-json: ## Show Terraform outputs in JSON
	terraform output -json | jq .

role-arn: ## Show GitHub Actions Role ARN
	@terraform output -raw github_actions_role_arn

ecr-url: ## Show ECR Repository URL
	@terraform output -raw ecr_repository_url

clean: ## Clean Terraform files
	rm -rf .terraform/
	rm -f .terraform.lock.hcl
	rm -f terraform.tfstate*
	rm -f outputs.json

format: ## Format Terraform files
	terraform fmt -recursive

docs: ## Generate documentation
	@echo "=== GitHub Actions Role ARN ==="
	@terraform output github_actions_role_arn
	@echo ""
	@echo "=== ECR Repository URL ==="
	@terraform output ecr_repository_url
	@echo ""
	@echo "=== Add this to GitHub Secrets ==="
	@echo "Name: AWS_ROLE_ARN"
	@echo "Value: $$(terraform output -raw github_actions_role_arn)"

setup: init apply docs ## Complete setup (init + apply + docs)

sync: ## Sync Terraform outputs to GitHub Secrets
	@echo "🔄 Syncing outputs to GitHub Secrets..."
	@./sync-to-github.sh

sync-check: ## Check what will be synced (dry-run)
	@echo "📋 Terraform Outputs:"
	@echo "===================="
	@echo "ECR Repository: $$(terraform output -raw ecr_repository_name)"
	@echo "ECR URL: $$(terraform output -raw ecr_repository_url)"
	@echo "Role ARN: $$(terraform output -raw github_actions_role_arn)"
	@echo "AWS Region: $$(terraform output -raw aws_region)"
	@echo "AWS Account: $$(terraform output -raw aws_account_id)"
	@echo ""
	@echo "GitHub Repo: $$(grep github_org terraform.tfvars | cut -d'"' -f2)/$$(grep github_repo terraform.tfvars | cut -d'"' -f2)"
