terraform {
  backend "s3" {
    key          = "opspilot/showcase/terraform.tfstate"
    use_lockfile = true
    encrypt      = true
  }
}
