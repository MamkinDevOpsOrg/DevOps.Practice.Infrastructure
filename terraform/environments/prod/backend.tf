terraform {
  backend "s3" {
    bucket = "tfstate-storage-for-mamkindevops-prod-1"
    key    = "envs/prod/terraform.tfstate"
    region = "us-west-2"
  }
}
