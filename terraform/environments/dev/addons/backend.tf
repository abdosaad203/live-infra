terraform {
  backend "s3" {
    bucket         = "route-state"
    key            = "dev/addons.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}