# This is just side stuff needed to run the example. The interesting part is in main.tf

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.unique_name
  cidr = "10.142.0.0/16"

  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
  private_subnets = ["10.142.1.0/24", "10.142.2.0/24", "10.142.3.0/24"]
  public_subnets  = ["10.142.101.0/24", "10.142.102.0/24", "10.142.103.0/24"]

  enable_nat_gateway = true

}

resource "aws_alb" "alb" {
  subnets = module.vpc.private_subnets
}

resource "aws_route53_health_check" "this" {
  fqdn              = "example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = "5"
  request_interval  = "30"
}
