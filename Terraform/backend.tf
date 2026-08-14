terraform {
  backend "s3" {
    bucket = "terraform-state-devops-grad"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
