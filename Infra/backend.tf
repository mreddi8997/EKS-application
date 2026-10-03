terraform {
  backend "s3" {
    bucket       = "terraform-backend-mohit"
    key          = "app/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
