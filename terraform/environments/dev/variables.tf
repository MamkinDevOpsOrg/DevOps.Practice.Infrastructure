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
  default = "app1-dev"
}

variable "target_group_name_prefix" {
  default = "app1-d"
}

variable "environment" {
  default = "dev"
}

variable "project" {
  default = "app1-dev"
}

variable "machine_image" {
  default = "ami-075686beab831bb7f" # Ubuntu Server 22.04 LTS (HVM)
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_pair_name" {
  default = "devops_practice"
}

variable "ec2_name_tag" {
  default = "app1-asg-instance-dev"
}

variable "ecr_repository_name" {
  default = "ecr-kapset-dev"
}

variable "analytics_db_username" {
  default = "analyticsdb_user"
}

variable "analytics_db_name" {
  default = "analyticsdbdev"
}

variable "s3_instance_name" {
  default = "tfstate-storage-for-mamkindevops-dev-1"
}

variable "analytics_db_password" {
  description = "Analytics database password"
  type        = string
}

variable "region" {
  default = "us-west-2"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag for app1 ECS task"
}
