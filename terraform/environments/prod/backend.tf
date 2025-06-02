terraform {
  backend "s3" {
    bucket = "tfstate-storage-for-mamkindevops-production"
    key    = "envs/prod/terraform.tfstate"
    region = "us-east-1"
  }
}
