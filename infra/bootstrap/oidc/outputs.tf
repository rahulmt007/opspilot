output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "github_oidc_subject" {
  value = local.github_subject
}

output "github_role_arn" {
  value = aws_iam_role.github_actions.arn
}
