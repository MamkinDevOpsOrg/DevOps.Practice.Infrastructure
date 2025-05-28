variable "region" {
  description = "Value of the region property for aws provider"
  type        = string
  default     = "us-west-1"
}

variable "s3_instance_name" {
  description = "Value of the name bucket in S3"
  type        = string
  default     = "tfstate-storage-for-mamkindevops-prod"
}