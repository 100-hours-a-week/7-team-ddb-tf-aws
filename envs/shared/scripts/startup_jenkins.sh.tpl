#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log | logger -t user-data -s 2>/dev/console) 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "▶ 시스템 패키지 업데이트"
sudo apt-get update -y
sudo apt-get install -y curl ca-certificates gnupg lsb-release unzip

echo "▶ Docker 설치"
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    gpg --dearmor | sudo tee /etc/apt/keyrings/docker.gpg > /dev/null

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "▶ Docker 데몬 실행 및 부팅 시 자동 시작 설정"
sudo systemctl start docker
sudo systemctl enable docker

echo "▶ Docker 그룹에 ubuntu 사용자 추가"
sudo usermod -aG docker ubuntu

echo "▶ AWS CLI 2 설치"
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
sudo ln -sf /usr/local/aws-cli/v2/current/bin/aws /usr/local/bin/aws
aws --version || echo "AWS CLI 설치에 실패했거나 경로 문제 발생"
rm -rf /tmp/aws /tmp/awscliv2.zip

echo "▶ volume 생성"
sudo docker volume create jenkins_home
sudo docker run --rm -v jenkins_home:/data busybox true

JENKINS_HOME="/var/lib/docker/volumes/jenkins_home/_data"
LATEST_BACKUP=$(aws s3 ls s3://backup-dolpin-aws/jenkins-backups/ \
  | sort -k1,2 \
  | tail -n 1 \
  | awk '{print $4}')

touch /tmp/restore.lock

(
  trap 'rm -f /tmp/restore.lock' EXIT
  if [ -z "$${LATEST_BACKUP}" ]; then
    echo "INFO: 백업 파일이 존재하지 않습니다. Jenkins를 초기 상태로 시작합니다."
  else
    aws s3 cp "s3://backup-dolpin-aws/jenkins-backups/$${LATEST_BACKUP}" /tmp/jenkins_backup_latest.tar.gz
    sudo mkdir -p "$${JENKINS_HOME}"
    sudo tar -xvzf /tmp/jenkins_backup_latest.tar.gz --strip-components=2 -C "$${JENKINS_HOME}"
    sudo chown -R 1000:1000 "$${JENKINS_HOME}"
  fi
) &

while [ -f /tmp/restore.lock ]; do
  sleep 1
done

echo "${dockerfile_content}" > /tmp/Dockerfile
echo "${dockercompose_content}" > /tmp/docker-compose.yml
cd /tmp
sudo docker compose up -d
