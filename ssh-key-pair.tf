resource "aws_key_pair" "deployer" {
  key_name   = "openethereum-${var.region}-keypair"
  public_key = var.ssh_pubkey
}

