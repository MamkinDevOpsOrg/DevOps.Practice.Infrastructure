resource "aws_ecs_cluster" "app1" {
  name = "${var.project}-cluster"
}

resource "aws_ecs_task_definition" "app1" {
  family                   = "${var.project}-task"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "app1"
      image = "${aws_ecr_repository.ecr.repository_url}:${var.image_tag}"
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENV"
          value = var.environment
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app1" {
  name             = "${var.project}-svc"
  cluster          = aws_ecs_cluster.app1.id
  task_definition  = aws_ecs_task_definition.app1.arn
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets          = module.vpc.private_subnets
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_service.id]
  }

  load_balancer {
    target_group_arn = module.alb.target_groups["app"].arn
    container_name   = "app1"
    container_port   = 8000
  }

  depends_on = [module.alb]
}
