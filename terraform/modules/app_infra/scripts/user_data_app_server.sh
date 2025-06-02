#!/bin/bash

# -----------------------------------------------------------------------------
# EC2 bootstrap script for autonomous provisioning of app1 container
#
# Responsibilities:
# - Disables IPv6 to ensure compatibility with IPv4-only NAT Gateway
# - Forces IPv4 DNS resolution priority to avoid broken IPv6 connections
# - Installs Docker (official method) and AWS CLI v2
# - Logs in to Amazon ECR using IAM instance role
# - Pulls and runs the latest version of the app1 container
#
# Output:
# - Execution log written to /var/log/user_data.bootstrap.log
# -----------------------------------------------------------------------------

(
echo "===== START FULL BOOTSTRAP ====="
date

# Completely disable IPv6 at the kernel level to prevent any attempts to use IPv6 addresses for outbound connections,
# since NAT Gateway in this setup supports only IPv4. This helps avoid failures in apt, curl, docker, and aws CLI
# caused by the system preferring unreachable IPv6 routes.
sysctl -w net.ipv6.conf.all.disable_ipv6=1
sysctl -w net.ipv6.conf.default.disable_ipv6=1
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf

# Force IPv4 to be preferred over IPv6 in name resolution by updating /etc/gai.conf.
# This ensures that DNS lookups (getaddrinfo) return IPv4 addresses first, even if IPv6 is available,
# avoiding broken connectivity in environments without IPv6 routing support (like EC2 with NAT only).
echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf

# Update package list and install dependencies
apt-get update -y
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  unzip

# Install Docker using the official method
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "✅ Docker installed: $(docker --version)"

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -o awscliv2.zip
./aws/install
export PATH=$PATH:/usr/local/bin

echo "✅ AWS CLI installed: $(aws --version)"

# Pull and run container from ECR
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="${region}"
REPO="ecr-kapset"
IMAGE="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO:latest"

aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

docker rm -f app1 || true
docker pull $IMAGE
docker run -d --name app1 -p 80:8000 $IMAGE

echo "===== DONE FULL BOOTSTRAP ====="
) > /var/log/user_data.bootstrap.log 2>&1
