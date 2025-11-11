terraform {
  backend "s3" {
    bucket         = "vetrii-terraform-state-bucket"
    key            = "vetrii-frontend/terraform.tfstate"
    region         = "us-east-2"
    dynamodb_table = "terraform-locks"
  }
}
