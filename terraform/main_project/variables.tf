variable "region" {
  description = "Value of the region property for aws provider"
  type        = string
  default     = "us-west-2"
}

variable "machine_image" {
  description = "Value of the ami property for the EC2 instance"
  type        = string
  default     = "ami-03f8acd418785369b" // Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
}

variable "instance_type" {
  description = "Value of the instance_type property for the EC2 instance"
  type        = string
  default     = "t2.micro"
}

variable "instance_name" {
  description = "Value of the Name tag for the EC2 instance"
  type        = string
  default     = "app_server"
}

variable "key_pair_name_for_ssh" {
  description = "Key-pair's name for ssh connection to EC2 instance"
  type        = string
  default     = "devops_practice"
}

variable "s3_instance_name" {
  description = "Value of the name bucket in S3"
  type        = string
  default     = "tfstate-storage-for-mamkindevops-dev-1"
}