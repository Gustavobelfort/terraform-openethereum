terraform {
  backend "s3" {
    region  = "us-east-1"
    bucket  = "terraform-state-storage-eth"
    key     = "state.tfstate"
    encrypt = true #AES-256 encryption
  }
}

provider "aws" {
  region  = var.region
  profile = var.aws_profile
}

resource "aws_key_pair" "deployer" {
  key_name   = "openethereum-${var.region}-keypair"
  public_key = var.ssh_pubkey
}

