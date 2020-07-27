data "template_file" "ethereum_user_data" {
  template = file("./provision-openethereum.sh")
  vars = {
    dir               = "/home/ubuntu/ethereum"
    region            = var.region
    network           = "mainnet"
    cloudwatch_id     = aws_iam_access_key.cloudwatch.id
    cloudwatch_secret = aws_iam_access_key.cloudwatch.secret
  }
}

resource "aws_instance" "ethereum" {
  ami               = data.aws_ami.ubuntu-18_04.id
  count             = var.eth_count
  availability_zone = aws_ebs_volume.ethereum_block_storage[0].availability_zone
  instance_type     = var.instance_type

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  security_groups = [aws_security_group.ethereum.id]

  key_name  = aws_key_pair.deployer.key_name
  subnet_id = module.vpc.first-subnet-id

  # user_data = local.ethereum_user_data
  user_data = data.template_file.ethereum_user_data.rendered

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname openethereum-${var.region}-${count.index + 1}",
    ]
  }

    connection {
      host        = self.public_ip
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_privkey_path)
    }

  # provisioner "file" {
  #   source      = "restart-parity.sh"
  #   destination = "/home/ubuntu/restart-parity.sh"
  # }

  tags = {
    Name = "openethereum-${count.index + 1}"
  }
}

