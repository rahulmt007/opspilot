variable "aws_region" {
  description = "Only AWS region the GitHub Actions role may manage."
  type        = string
  default     = "us-east-1"
}

variable "github_owner" {
  description = "GitHub repository owner used in the OIDC subject claim."
  type        = string
  default     = "rahulmt007"
}

variable "github_repository" {
  description = "GitHub repository name used in the OIDC subject claim."
  type        = string
  default     = "opspilot"
}

variable "github_environment" {
  description = "Protected GitHub environment allowed to assume the role."
  type        = string
  default     = "aws-showcase"
}

variable "create_oidc_provider" {
  description = "Create the account-wide GitHub OIDC provider. Set false when one already exists."
  type        = bool
  default     = true
}

variable "existing_oidc_provider_arn" {
  description = "Existing GitHub OIDC provider ARN when create_oidc_provider is false."
  type        = string
  default     = null

  validation {
    condition     = var.create_oidc_provider || var.existing_oidc_provider_arn != null
    error_message = "Set existing_oidc_provider_arn when create_oidc_provider is false."
  }
}
