data "aws_caller_identity" "current" {}

check "oidc_provider_configuration" {
  assert {
    condition     = var.create_oidc_provider || var.existing_oidc_provider_arn != null
    error_message = "Set existing_oidc_provider_arn when create_oidc_provider is false."
  }
}

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_oidc_provider ? 1 : 0

  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  # Preserve the existing GitHub OIDC provider thumbprint during showcase updates.
  thumbprint_list = ["ab9d0263244dd0326eb67015705a667e79cfe998"]

  tags = {
    Project   = "opspilot"
    ManagedBy = "terraform-bootstrap"
  }
}

locals {
  oidc_provider_arn = var.create_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_oidc_provider_arn
  github_subject    = "repo:${var.github_owner}/${var.github_repository}:environment:${var.github_environment}"
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [local.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values   = [local.github_subject]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name                 = "opspilot-github-actions"
  description          = "Short-lived GitHub OIDC role for the OpsPilot AWS showcase"
  assume_role_policy   = data.aws_iam_policy_document.github_trust.json
  max_session_duration = 3600

  tags = {
    Project   = "opspilot"
    ManagedBy = "terraform-bootstrap"
  }
}

data "aws_iam_policy_document" "showcase" {
  statement {
    sid       = "ReadEC2Metadata"
    effect    = "Allow"
    actions   = ["ec2:Describe*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageShowcaseNetwork"
    effect = "Allow"
    actions = [
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateInternetGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReplaceRoute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid    = "ManageShowcaseInstances"
    effect = "Allow"
    actions = [
      "ec2:DeleteKeyPair",
      "ec2:ImportKeyPair",
      "ec2:ModifyInstanceAttribute",
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  statement {
    sid       = "LaunchOnlyMicroInstances"
    effect    = "Allow"
    actions   = ["ec2:RunInstances"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:InstanceType"
      values   = ["t3.micro"]
    }
  }

  statement {
    sid    = "ManageProjectBudget"
    effect = "Allow"
    actions = [
      "budgets:ModifyBudget",
      "budgets:ViewBudget"
    ]
    resources = ["arn:aws:budgets::${data.aws_caller_identity.current.account_id}:budget/opspilot-*"]
  }

  statement {
    sid       = "ReadBillingViewForBudget"
    effect    = "Allow"
    actions   = ["billing:GetBillingViewData"]
    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.terraform_state_bucket == "" ? [] : [var.terraform_state_bucket]
    content {
      sid       = "ManageTerraformState"
      effect    = "Allow"
      actions   = ["s3:ListBucket"]
      resources = ["arn:aws:s3:::${statement.value}"]

      condition {
        test     = "StringLike"
        variable = "s3:prefix"
        values   = [var.terraform_state_key, "${var.terraform_state_key}.tflock"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.terraform_state_bucket == "" ? [] : [var.terraform_state_bucket]
    content {
      sid    = "ReadWriteTerraformState"
      effect = "Allow"
      actions = [
        "s3:DeleteObject",
        "s3:GetObject",
        "s3:PutObject"
      ]
      resources = [
        "arn:aws:s3:::${statement.value}/${var.terraform_state_key}",
        "arn:aws:s3:::${statement.value}/${var.terraform_state_key}.tflock"
      ]
    }
  }
}

resource "aws_iam_role_policy" "showcase" {
  name   = "opspilot-showcase"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.showcase.json
}
