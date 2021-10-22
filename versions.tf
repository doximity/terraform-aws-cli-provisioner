terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.48.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1"
    }
  }
  required_version = ">= 0.12"
}
