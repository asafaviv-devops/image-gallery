# Terraform Execution Role with Least Privilege
# Replaces: terraform/eks_cluster/bootstrap/iam-terraform-role.tf

locals {
  terraform_user_arn = "arn:aws:iam::184890426414:user/asaf_aviv"
}

data "aws_iam_policy_document" "terraform_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = [local.terraform_user_arn]
    }
    
    # OPTIONAL: Add MFA requirement for production
    # Uncomment for additional security:
    # condition {
    #   test     = "Bool"
    #   variable = "aws:MultiFactorAuthPresent"
    #   values   = ["true"]
    # }
  }
}

resource "aws_iam_role" "terraform_execution_role" {
  name               = "TerraformExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json
  
  tags = {
    Name        = "TerraformExecutionRole"
    Purpose     = "Terraform EKS Cluster Management"
    ManagedBy   = "Terraform"
  }
}

# Policy for EKS Cluster Management
resource "aws_iam_policy" "terraform_eks_management" {
  name        = "TerraformEKSManagementPolicy"
  description = "Least privilege policy for Terraform to manage EKS clusters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EKSClusterManagement"
        Effect = "Allow"
        Action = [
          "eks:CreateCluster",
          "eks:DeleteCluster",
          "eks:DescribeCluster",
          "eks:UpdateClusterVersion",
          "eks:UpdateClusterConfig",
          "eks:ListClusters",
          "eks:TagResource",
          "eks:UntagResource",
          "eks:CreateAddon",
          "eks:DeleteAddon",
          "eks:DescribeAddon",
          "eks:UpdateAddon",
          "eks:ListAddons",
          "eks:DescribeAddonVersions",
          "eks:CreateNodegroup",
          "eks:DeleteNodegroup",
          "eks:DescribeNodegroup",
          "eks:UpdateNodegroupVersion",
          "eks:UpdateNodegroupConfig",
          "eks:ListNodegroups"
        ]
        Resource = [
          "arn:aws:eks:*:*:cluster/image-gallery-*",
          "arn:aws:eks:*:*:nodegroup/image-gallery-*/*/*",
          "arn:aws:eks:*:*:addon/*/*/*"
        ]
      },
      {
        Sid    = "VPCManagement"
        Effect = "Allow"
        Action = [
          "ec2:CreateVpc",
          "ec2:DeleteVpc",
          "ec2:DescribeVpcs",
          "ec2:ModifyVpcAttribute",
          "ec2:CreateSubnet",
          "ec2:DeleteSubnet",
          "ec2:DescribeSubnets",
          "ec2:ModifySubnetAttribute",
          "ec2:CreateInternetGateway",
          "ec2:DeleteInternetGateway",
          "ec2:AttachInternetGateway",
          "ec2:DetachInternetGateway",
          "ec2:DescribeInternetGateways",
          "ec2:CreateNatGateway",
          "ec2:DeleteNatGateway",
          "ec2:DescribeNatGateways",
          "ec2:CreateRouteTable",
          "ec2:DeleteRouteTable",
          "ec2:DescribeRouteTables",
          "ec2:AssociateRouteTable",
          "ec2:DisassociateRouteTable",
          "ec2:CreateRoute",
          "ec2:DeleteRoute",
          "ec2:ReplaceRoute",
          "ec2:AllocateAddress",
          "ec2:ReleaseAddress",
          "ec2:DescribeAddresses",
          "ec2:CreateTags",
          "ec2:DeleteTags",
          "ec2:DescribeTags",
          "ec2:CreateSecurityGroup",
          "ec2:DeleteSecurityGroup",
          "ec2:DescribeSecurityGroups",
          "ec2:AuthorizeSecurityGroupIngress",
          "ec2:RevokeSecurityGroupIngress",
          "ec2:AuthorizeSecurityGroupEgress",
          "ec2:RevokeSecurityGroupEgress"
        ]
        Resource = "*"
      },
      {
        Sid    = "IAMManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:GetRole",
          "iam:DeleteRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:ListRolePolicies",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:CreatePolicy",
          "iam:GetPolicy",
          "iam:DeletePolicy",
          "iam:CreateOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider"
        ]
        Resource = [
          "arn:aws:iam::*:role/image-gallery-*",
          "arn:aws:iam::*:role/eks-*",
          "arn:aws:iam::*:policy/image-gallery-*",
          "arn:aws:iam::*:oidc-provider/oidc.eks.*"
        ]
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:DescribeLogGroups",
          "logs:PutRetentionPolicy",
          "logs:TagLogGroup"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/eks/image-gallery-*"
      },
      {
        Sid    = "AutoScaling"
        Effect = "Allow"
        Action = [
          "autoscaling:CreateAutoScalingGroup",
          "autoscaling:DeleteAutoScalingGroup",
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:CreateOrUpdateTags"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2LaunchTemplates"
        Effect = "Allow"
        Action = [
          "ec2:CreateLaunchTemplate",
          "ec2:DeleteLaunchTemplate",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2Describe"
        Effect = "Allow"
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeImages",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeNetworkInterfaces"
        ]
        Resource = "*"
      },
      {
        Sid    = "STSIdentity"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_eks_management" {
  role       = aws_iam_role.terraform_execution_role.name
  policy_arn = aws_iam_policy.terraform_eks_management.arn
}

output "terraform_execution_role_arn" {
  value       = aws_iam_role.terraform_execution_role.arn
  description = "ARN of Terraform execution role"
}

output "terraform_execution_role_name" {
  value       = aws_iam_role.terraform_execution_role.name
  description = "Name of Terraform execution role"
}
