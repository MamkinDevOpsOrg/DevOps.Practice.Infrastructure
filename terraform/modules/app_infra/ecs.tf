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
        },
        {
          name  = "ANALYTICS_STATS_URL"
          value = "http://${aws_api_gateway_rest_api.analytics_api.id}.execute-api.${var.region}.amazonaws.com/${var.environment}/analytics-stats"
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "app1" {
  name             = "${var.project}-svc"
  cluster          = aws_ecs_cluster.app1.id
  task_definition  = aws_ecs_task_definition.app1.arn
  desired_count    = 2
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  # Ensure zero-downtime rolling deployments and debuggability:
  # - 100% healthy tasks must be running before stopping old ones
  # - Allow up to 200% of desired tasks during deployment
  # - Wait 30s before ALB health checks (startup buffer)
  # - Enable ECS Exec for container debugging via CLI
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 30
  enable_execute_command             = true

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

resource "aws_appautoscaling_target" "ecs_app1" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app1.name}/${aws_ecs_service.app1.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  min_capacity       = 2
  max_capacity       = 5
}

resource "aws_appautoscaling_policy" "ecs_app1_scale_up_down" {
  name               = "${var.project}-cpu-scaling"
  service_namespace  = aws_appautoscaling_target.ecs_app1.service_namespace
  resource_id        = aws_appautoscaling_target.ecs_app1.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_app1.scalable_dimension
  policy_type        = "TargetTrackingScaling"

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value       = 60.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 60
  }
}
