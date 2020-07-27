set -e

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


# add docker's own apt repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Basic packages and unattended security upgrades
echo unattended-upgrades unattended-upgrades/enable_auto_updates boolean true | debconf-set-selections
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y unattended-upgrades docker-ce unzip socat

# Take any security upgrades immediately
unattended-upgrade

# Latest AWS Tools (the version in apt is old)
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
python3 ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

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

# run geth from docker hub
if [ ${network} == "mainnet" ]; then
  ${network}=""
fi

docker run -d --name ethereum-node --restart always -v ${dir}:/root \
     -p 8545:8545 -p 8546:8546 -p 30303:30303 \
     ethereum/client-go:stable ${network} \
     --rpc --rpcapi eth,net,web3 --rpcaddr 0.0.0.0 \
     --ws --wsaddr 0.0.0.0 --wsorigins '*' --wsapi eth,net,web3 \
     --cache 4096
