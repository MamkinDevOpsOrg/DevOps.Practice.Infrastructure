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
      target_type       = "ip" # 'ip' type is required for Fargate+awsvpc, for EC2 use 'instance' type
      create_attachment = false

      health_check = {
        enabled             = true
        path                = "/v1/friends"
        port                = "traffic-port"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 2
        unhealthy_threshold = 3
      }
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