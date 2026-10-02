terraform {
  backend "s3" {
    bucket       = "terraform-backend-mohit"
    key          = "app/terraform.tfstate"
    region       = "us-west-1"
    encrypt      = true
    use_lockfile = true
  }
}
