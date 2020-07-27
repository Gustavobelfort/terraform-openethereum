resource "aws_key_pair" "deployer" {
  key_name   = "openethereum-${var.region}-keypair"
  public_key = file(var.ssh_keypath)
}

