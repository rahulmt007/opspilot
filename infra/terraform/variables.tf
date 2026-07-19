variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project" {
  type    = string
  default = "opspilot"
}
variable "owner" { type = string }
variable "image_repository" {
  type        = string
  description = "OCI image repository containing the published OpsPilot image."
  default     = "ghcr.io/rahulmt007/opspilot"
}
variable "image_digest" {
  type        = string
  description = "Immutable sha256 digest of the image to deploy."

  validation {
    condition     = can(regex("^sha256:[0-9a-f]{64}$", var.image_digest))
    error_message = "image_digest must be a full sha256 digest."
  }
}
variable "expires_at" {
  type        = string
  description = "UTC ISO-8601 cleanup deadline"
}
variable "instance_type" {
  type    = string
  default = "t3.micro"
}
variable "root_volume_gb" {
  type    = number
  default = 8
}
variable "ssh_cidrs" {
  type    = list(string)
  default = []
  validation {
    condition     = alltrue([for cidr in var.ssh_cidrs : can(regex("/32$", cidr))])
    error_message = "Every SSH CIDR must identify one IPv4 address with a /32 suffix."
  }
}
variable "public_key" {
  type      = string
  sensitive = true
  default   = ""
}
variable "budget_usd" {
  type    = number
  default = 5
}
variable "budget_email" {
  type    = string
  default = ""
}

locals {
  tags = {
    Project     = var.project
    Environment = "showcase"
    Owner       = var.owner
    ExpiresAt   = var.expires_at
    ManagedBy   = "terraform"
  }
}
