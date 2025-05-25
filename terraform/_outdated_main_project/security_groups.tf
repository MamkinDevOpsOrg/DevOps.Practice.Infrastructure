resource "aws_security_group" "app_sg" {
  name        = "app-server-sg"
  description = "Allow HTTP from ALB and SSH from anywhere"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "Allow HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [module.alb.security_group_id]
  }

  ingress {
    description     = "Allow SSH from anywhere"
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
    Name = "app-server-sg"
  }
}

resource "aws_security_group" "lambda_db_sg" {
  name        = "analytics-lambda-sg"
  description = "Allow Lambda to access anything needed"
  vpc_id      = module.vpc.vpc_id

  egress {
    description = "Allow all outbound traffic (including to RDS, Internet)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "analytics-lambda-sg"
  }
}
