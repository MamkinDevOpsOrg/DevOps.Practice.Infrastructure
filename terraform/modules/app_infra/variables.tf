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

variable "machine_image" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_pair_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "ec2_name_tag" {
  description = "Tag 'Name' for EC2 instances in ASG"
  type        = string
}

variable "ecr_repository_name" {
  description = "Name of ECR repository"
  type        = string
}
