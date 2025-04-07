module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.15.0"

  name               = "app1-alb"
  load_balancer_type = "application"
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.public_subnets

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
      name_prefix = "app1"
      protocol    = "HTTP"
      port        = 80
      target_type = "instance"
      target_id   = aws_instance.app_server.id
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
    Environment = "dev"
    Project     = "app1"
  }
}
