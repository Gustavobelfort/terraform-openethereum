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

docker run -it -d -p 9090:9090 \
  -e "GETH=${rpc_endpoint} \
  hunterlong/gethexporter