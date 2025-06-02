resource "aws_security_group" "rds_sg" {
  name        = "analytics-rds-sg"
  description = "Allow access to RDS only from Lambda security group"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description     = "PostgreSQL access from Lambda"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.lambda_db_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "analytics-rds-sg-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "analytics_rds_subnet_group" {
  name       = "analytics-rds-subnet-group-${var.environment}"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name = "analytics-rds-subnet-group-${var.environment}"
  }
}

resource "aws_db_instance" "analytics_db" {
  identifier             = "analytics-db-${var.environment}"
  engine                 = "postgres"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  storage_type           = "gp2"
  username               = var.analytics_db_username
  password               = var.analytics_db_password
  db_name                = var.analytics_db_name
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.analytics_rds_subnet_group.name

  backup_retention_period = 7
  availability_zone       = "${var.region}a"

  tags = {
    Name        = "analytics-db-${var.environment}"
    Environment = var.environment
  }
}
