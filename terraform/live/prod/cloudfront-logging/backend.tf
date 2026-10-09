terraform {
  backend "s3" {
    bucket       = "cvascode-814023476338-terraform-state"
    key          = "prod/cloudfront-logging/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
