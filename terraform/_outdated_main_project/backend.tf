terraform {
  backend "s3" {
    bucket = "tfstate-storage-for-mamkindevops-dev-1"
    key    = "tfstate/terraform.tfstate"
    region = "us-west-2"
  }
}
