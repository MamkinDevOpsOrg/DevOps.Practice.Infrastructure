// ==== VPC ====
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"

  name = var.vpc_name
  cidr = var.vpc_cidr_block

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_network_acl = false

  tags = {
    Environment = var.environment
    Project     = var.project
  }
}

// ==== ALB ====
module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.15.0"

  name               = var.alb_name
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

  access_logs = {
    bucket  = var.access_log_bucket
    prefix  = var.access_log_prefix
    enabled = true
  }

  security_group_ingress_rules = {
    http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  target_groups = {
    app = {
      name_prefix       = var.target_group_name_prefix
      protocol          = "HTTP"
      port              = 80
      target_type       = "instance"
      create_attachment = false
    }
  }

  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "app"
      }
    }
  }

  tags = {
    Environment = var.environment
    Project     = var.project
  }

  enable_deletion_protection = false
}

// ==== Security Group for Launch template ====
resource "aws_security_group" "app_sg" {
  name        = "${var.environment}-app-server-sg"
  description = "Allow HTTP and SSH from ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  ingress {
    description     = "Allow SSH from ALB (for testing or tunneling)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-app-server-sg"
    Environment = var.environment
    Project     = var.project
  }
}

// ==== Launch template ====
resource "aws_launch_template" "app_server" {
  name_prefix   = "app1-launch-template"
  image_id      = var.machine_image
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  key_name = var.key_pair_name

  user_data = filebase64("${path.module}/scripts/user_data_app_server.sh")

  vpc_security_group_ids = [aws_security_group.app_sg.id]

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = var.ec2_name_tag
    }
  }
}

resource "aws_autoscaling_group" "app1_asg" {
  name                      = "app1-asg"
  desired_capacity          = 1
  max_size                  = 3
  min_size                  = 1
  vpc_zone_identifier       = module.vpc.private_subnets
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.app_server.id
    version = "$Latest"
  }

  target_group_arns = [module.alb.target_groups["app"].arn]

  tag {
    key                 = "Name"
    value               = var.ec2_name_tag
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

// ==== IAM role and Instance profile ====
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

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-ecr-access-profile"
  role = aws_iam_role.ec2_role.name
}
