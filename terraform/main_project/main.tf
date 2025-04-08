terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

# Get current AWS Account ID
data "aws_caller_identity" "current" {}

# IAM Role for EC2 to access ECR
resource "aws_iam_role" "ec2_role" {
  name = "ec2-ecr-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

# Attach AmazonEC2ContainerRegistryReadOnly policy
resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Instance profile for EC2
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-ecr-access-profile"
  role = aws_iam_role.ec2_role.name
}

# EC2 app server
resource "aws_instance" "app_server" {
  ami                    = var.machine_image
  instance_type          = var.instance_type
  key_name               = var.key_pair_name_for_ssh
  iam_instance_profile   = aws_iam_instance_profile.ec2_instance_profile.name
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = module.vpc.private_subnets[0]

  tags = {
    Name = var.instance_name
  }
}

# EC2 bastion host
resource "aws_instance" "bastion_host" {
  ami                         = var.machine_image
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  key_name                    = var.key_pair_name_for_ssh
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion_host"
  }
}
