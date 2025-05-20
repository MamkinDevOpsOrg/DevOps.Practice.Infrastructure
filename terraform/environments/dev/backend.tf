terraform {
  backend "s3" {
    bucket = "tfstate-storage-for-mamkindevops-dev-1"
    key    = "envs/dev/terraform.tfstate"
    region = "us-west-2"
  }
}
