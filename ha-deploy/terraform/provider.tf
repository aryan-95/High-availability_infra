provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "HA-Deploy"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}
