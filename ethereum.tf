locals {
  ethereum_user_data = <<TFEOF
#! /bin/bash

apt-get update && apt-get install -y supervisor curl unzip

# Install Node.js
curl -sL https://deb.nodesource.com/setup_10.x | bash -
apt install nodejs
echo "Node.js is installed with the following versions:"
node -v
npm -v

echo "Waiting to see if the 50G disk was mounted.."
while true; do
  sleep 1
  BLOCK_STORAGE_NAME=$(lsblk | grep 50G | awk '{print $1}')
  [ ! -z "$BLOCK_STORAGE_NAME" ] && break
done
echo "Found the 50G SSD disk on $BLOCK_STORAGE_NAME , attempting to mount it.."

mkdir -p /home/root/.local
mkfs -t xfs /dev/$BLOCK_STORAGE_NAME
echo "/dev/$BLOCK_STORAGE_NAME /home/root/.local xfs defaults,nofail 0 0" >> /etc/fstab
mount -a

cd /home/ubuntu && wget https://github.com/openethereum/openethereum/releases/download/v3.0.1/openethereum-linux-v3.0.1.zip
unzip openethereum-linux-v3.0.1.zip
chmod u+x openethereum

(crontab -l 2>/dev/null; echo "0 */1 * * *  /usr/bin/node /home/ubuntu/check-ethereum.js ${var.slack_webhook_url} >> /var/log/manager.log") | crontab -

echo "[program:healthcheck]
command=/usr/bin/node /home/ubuntu/health.js
autostart=true
autorestart=true" >> /etc/supervisor/conf.d/health.conf

echo "[program:ethereum]
command=/home/ubuntu/openethereum --chain mainnet --db-path=/home/root/.local --min-peers=25 --max-peers=60 --no-secretstore --jsonrpc-interface all --no-ipc --no-ws
autostart=true
autorestart=true
stderr_logfile=/var/log/ethereum.err.log
stdout_logfile=/var/log/ethereum.out.log" >> /etc/supervisor/conf.d/ethereum.conf

supervisorctl reread && supervisorctl update

mkdir -p ~/.aws

# Setup AWS credentials for CloudWatch Agent
echo "[default]
aws_access_key_id = ${aws_iam_access_key.cloudwatch.id}
aws_secret_access_key = ${aws_iam_access_key.cloudwatch.secret}
" >> ~/.aws/credentials

echo "[default]
region=${var.region}
output=json" >> ~/.aws/config

# Installing AWS CloudWatch Agent
wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb

dpkg -i -E ./amazon-cloudwatch-agent.deb
wget https://raw.githubusercontent.com/orbs-network/terraform-ethereum-node/master/cloudwatch-agent-config.json
mv cloudwatch-agent-config.json /etc/

wget https://raw.githubusercontent.com/orbs-network/terraform-ethereum-node/master/cloudwatch-common-config.toml
mv cloudwatch-common-config.toml /opt/aws/amazon-cloudwatch-agent/etc/common-config.toml

mkdir -p /usr/share/collectd/
touch /usr/share/collectd/types.db

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a append-config -m ec2 -c file:/etc/cloudwatch-agent-config.json -s
amazon-cloudwatch-agent-ctl -a start

TFEOF

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

  # This machine type is chosen since we need at least 16GB of RAM for mainnet
  # and sufficent amount of networking capabilities
  security_groups = [aws_security_group.ethereum.id]

  key_name  = aws_key_pair.deployer.key_name
  subnet_id = module.vpc.first-subnet-id

  user_data = local.ethereum_user_data

  provisioner "remote-exec" {
    inline = [
      "sudo hostnamectl set-hostname openethereum-${var.region}-${count.index + 1}",
    ]
  }

  provisioner "file" {
    source      = "restart-parity.sh"
    destination = "/home/ubuntu/restart-parity.sh"
  }

  provisioner "file" {
    source      = "package.json"
    destination = "/home/ubuntu/package.json"
  }

  provisioner "file" {
    source      = "health.js"
    destination = "/home/ubuntu/health.js"
  }

  provisioner "file" {
    source      = "check-ethereum.js"
    destination = "/home/ubuntu/check-ethereum.js"
  }

  provisioner "file" {
    source      = "ethereum-lib.js"
    destination = "/home/ubuntu/ethereum-lib.js"
  }

  tags = {
    Name = "openethereum-${count.index + 1}"
  }
}

