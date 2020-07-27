# Backend configuration is loaded early so we can't use variables
terraform {
  backend "s3" {
    region  = "us-east-1"
    bucket  = "terraform-state-storage-eth"
    key     = "state.tfstate"
    encrypt = true #AES-256 encryption
  }
}

