terraform {
  backend "s3" {
    bucket         = "route-state"
    key            = "shared/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}