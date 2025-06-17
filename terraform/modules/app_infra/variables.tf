variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "vpc_cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "availability_zones" {
  type        = list(string)
  description = "AZs to spread resources across"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "List of CIDRs for private subnets"
}

variable "alb_name" {
  type        = string
  description = "Name of the ALB"
}

variable "access_log_bucket" {
  type        = string
  description = "S3 bucket name for ALB access logs"
}

variable "access_log_prefix" {
  type        = string
  description = "Prefix path for logs in S3"
}

variable "target_group_name_prefix" {
  type        = string
  description = "Prefix for ALB Target Group"
}

variable "environment" {
  type        = string
  description = "Environment name (dev, test, prod)"
}

variable "project" {
  type        = string
  description = "Project tag"
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of ECR repository"
  type        = string
}

variable "analytics_db_username" {
  description = "Username for analytics database"
  type        = string
}

variable "analytics_db_password" {
  description = "Password for analytics database"
  type        = string
  sensitive   = true
}

variable "analytics_db_name" {
  description = "Database name for analytics database"
  type        = string
}

variable "s3_instance_name" {
  description = "S3 bucket where lambda zips are stored"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "image_tag" {
  description = "Docker image tag for app1"
  type        = string
}
