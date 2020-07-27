data "aws_availability_zones" "available" {
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

module "vpc" {
  source = "./modules/vpc/public-only"

  name           = "${var.application}-vpc"
  application    = var.application
  provisionersrc = var.provisionersrc

  azs  = data.aws_availability_zones.available.names[0]
  cidr = var.vpc_cidr_block
}

