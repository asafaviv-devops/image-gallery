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
  }
}

resource "aws_iam_role" "terraform_execution_role" {
  name               = "TerraformExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.terraform_assume_role.json
}

resource "aws_iam_role_policy_attachment" "terraform_admin" {
  role       = aws_iam_role.terraform_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "terraform_execution_role_arn" {
  value = aws_iam_role.terraform_execution_role.arn
}

