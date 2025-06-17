variable "vpc_name" {
  default = "prod-vpc"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnet_cidrs" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  default = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "alb_name" {
  default = "app1-alb-prod"
}

variable "access_log_bucket" {
  default = "alb-access-logs-storage-for-mamkindevops-production"
}

variable "access_log_prefix" {
  default = "app1-prod"
}

variable "target_group_name_prefix" {
  default = "app1-p"
}

variable "environment" {
  default = "prod"
}

variable "project" {
  default = "app1-prod"
}

variable "key_pair_name" {
  default = "devops_practice_prod_us_east_1"
}

variable "ecr_repository_name" {
  default = "ecr-kapset-prod"
}

variable "analytics_db_username" {
  default = "analyticsdb_user"
}

variable "analytics_db_name" {
  default = "analyticsdbprod"
}

variable "s3_instance_name" {
  default = "tfstate-storage-for-mamkindevops-production"
}

variable "analytics_db_password" {
  description = "Analytics database password"
  type        = string
}

variable "region" {
  default = "us-east-1"
}

variable "image_tag" {
  type        = string
  description = "Docker image tag for app1 ECS task"
}
