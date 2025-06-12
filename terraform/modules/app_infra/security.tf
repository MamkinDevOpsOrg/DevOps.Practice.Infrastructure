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

resource "aws_security_group" "ecs_service" {
  name        = "${var.project}-ecs-sg"
  description = "Allow ALB to reach ECS containers"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
