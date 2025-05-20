variable "vpc_name" {
  default = "dev-vpc"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default = ["us-west-2a", "us-west-2b"]
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "alb_name" {
  default = "app1-alb-dev"
}

variable "access_log_bucket" {
  default = "alb-access-logs-storage-for-mamkindevops-dev-1"
}
variable "access_log_prefix" {
  default = "app1"
}
variable "target_group_name_prefix" {
  default = "app1"
}
variable "environment" {
  default = "dev"
}
variable "project" {
  default = "app1"
}
