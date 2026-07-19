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
}

variable "terraform_state_bucket" {
  description = "Pre-created S3 bucket used for the showcase Terraform state."
  type        = string
  default     = ""
}

variable "terraform_state_key" {
  description = "State object key inside the pre-created Terraform state bucket."
  type        = string
  default     = "opspilot/showcase/terraform.tfstate"
}
