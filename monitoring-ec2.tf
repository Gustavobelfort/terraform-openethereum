resource "aws_security_group" "monitoring" {
  name        = "monitoring-sg"
  description = "Security Group for the monitoring VM"
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

resource "aws_instance" "monitoring" {
  ami               = data.aws_ami.ubuntu-18_04.id
  count             = var.eth_count
  availability_zone = "us-east-1a"
  instance_type     = var.instance_type

  root_block_device {
    volume_type = "gp2"
    volume_size = 50
  }

  vpc_security_group_ids = [aws_security_group.monitoring.id]

  key_name          = aws_key_pair.deployer.key_name
  subnet_id         = aws_subnet.us-east-1a-private.id
  source_dest_check = false

  user_data = data.template_file.monitoring_user_data.rendered

  tags = {
    Name = "openethereum-instance"
  }
}

data "template_file" "monitoring_user_data" {
  template = file("./src/provision-monitoring.sh")
  vars = {
    rpc_endpoint = "http://${aws_instance.ethereum[0].private_ip}:8545"
  }
}
