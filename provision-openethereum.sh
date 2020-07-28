#!/bin/sh

set -e

sudo hostnamectl set-hostname "openethereum-instance"

# add docker's own apt repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Basic packages and unattended security upgrades
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades docker-ce docker-compose unzip socat

# Take any security upgrades immediately
unattended-upgrade

mkdir -p ~/.aws

# Setup AWS credentials for CloudWatch Agent
echo "[default]
aws_access_key_id = ${cloudwatch_id}
aws_secret_access_key = ${cloudwatch_secret}
" >> ~/.aws/credentials

echo "[default]
region=${region}
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

sudo docker run -d --name ethereum-node --restart always -v ${dir}:/root \
     -p 8545:8545 -p 8546:8546 -p 30303:30303 \
     openethereum/openethereum:latest --chain ${network} \
     --jsonrpc-interface=all --jsonrpc-apis=safe \
     --nat=extip:${nat_ip}
