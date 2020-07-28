data "aws_availability_zones" "available" {
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}
