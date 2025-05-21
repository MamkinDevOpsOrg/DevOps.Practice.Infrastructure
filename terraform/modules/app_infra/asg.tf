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

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
  }

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