#!/bin/bash
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

echo "▶ 시스템 패키지 업데이트"
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg lsb-release jq

echo "▶ Docker 설치"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "▶ Docker 데몬 실행 및 부팅 시 자동 시작 설정"
sudo systemctl start docker
sudo systemctl enable docker

echo "▶ Docker 그룹에 ubuntu 사용자 추가"
sudo usermod -aG docker ubuntu

echo "▶ CodeDeploy Agent 설치"
cd /home/ubuntu
sudo apt-get update
sudo apt-get install -y ruby wget
wget https://aws-codedeploy-ap-northeast-2.s3.amazonaws.com/latest/install
chmod +x ./install
sudo ./install auto
sudo service codedeploy-agent start
sudo service codedeploy-agent status

echo "▶ AWS CLI 2 설치"
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip

echo "▶ Node Exporter 컨테이너 실행"
sudo docker run -d \
  --name node-exporter \
  --restart unless-stopped \
  -p 9100:9100 \
  prom/node-exporter:v1.9.1

echo "✅ startup.sh 완료"