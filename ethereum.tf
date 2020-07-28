resource "aws_security_group" "ethereum" {
  name        = "ethereum-sg"
  description = "Security Group for the ethereum VM"
  vpc_id      = aws_vpc.default.id

  // SSH Connection
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 8545
    to_port     = 8545
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.application}-sg"
  }
}

resource "aws_instance" "ethereum" {
  ami               = data.aws_ami.ubuntu-18_04.id
  count             = var.eth_count
  availability_zone = "us-east-1a"
  instance_type     = var.instance_type

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  vpc_security_group_ids = [aws_security_group.ethereum.id]

  key_name          = aws_key_pair.deployer.key_name
  subnet_id         = aws_subnet.us-east-1a-private.id
  source_dest_check = false

  # user_data = local.ethereum_user_data
  user_data = data.template_file.ethereum_user_data.rendered

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname openethereum-${var.region}-${count.index + 1}",
    ]
  }

  connection {
    host         = self.private_ip
    type         = "ssh"
    user         = "ubuntu"
    bastion_user = "ec2-user"
    bastion_host = aws_instance.nat.public_ip
    private_key  = var.ssh_privkey
  }

  # provisioner "file" {
  #   source      = "restart-parity.sh"
  #   destination = "/home/ubuntu/restart-parity.sh"
  # }

  tags = {
    Name = "openethereum-${count.index + 1}"
  }
}

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
