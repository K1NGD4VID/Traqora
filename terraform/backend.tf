terraform {
  backend "s3" {
    bucket         = "traqora-terraform-state"
    key            = "infra/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "traqora-terraform-locks"
  }
}
