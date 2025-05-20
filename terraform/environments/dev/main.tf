module "app" {
  source = "../../modules/app_infra"

  vpc_name                 = var.vpc_name
  vpc_cidr_block           = var.vpc_cidr_block
  availability_zones       = var.availability_zones
  public_subnet_cidrs      = var.public_subnet_cidrs
  private_subnet_cidrs     = var.private_subnet_cidrs
  alb_name                 = var.alb_name
  access_log_bucket        = var.access_log_bucket
  access_log_prefix        = var.access_log_prefix
  target_group_name_prefix = var.target_group_name_prefix
  environment              = var.environment
  project                  = var.project
  machine_image            = var.machine_image
  instance_type            = var.instance_type
  key_pair_name            = var.key_pair_name
  ec2_name_tag             = var.ec2_name_tag
}
