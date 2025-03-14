terraform {
  backend "s3" {
    bucket = "terra-state-new-infra-remya-123"
    key    = "terraform/terraform.tfstate"
    region = "us-east-1"
  }
}
