variable "aws_region" {
  type    = string
  default = "us-east-1"
}
variable "project" {
  type    = string
  default = "opspilot"
}
variable "owner" { type = string }
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
