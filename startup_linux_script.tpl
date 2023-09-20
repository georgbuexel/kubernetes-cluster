#!/bin/bash -ex
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo BEGIN

# Setup SSH Key
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC0YlYQ6TcFvUxOhVlRERYEdl5XaoPIjdQ0cLOk40tBt2vpAx0ms3v20GakgI5YcqGEnEF+tRoVpUIllorurRUkMUifwOeRaJkCSsZQ91tNa3/vM3etEJKPI1WuaDeP+B+CDRq6W897DSHvQCHzfZbwdR8BnVnL18KmPvVo5rZDYEZgl6aXPTv+mrJ1qXdbo7HQCqnJwVwSd+lV2drMgEWt66rHmLrs/ozg+Dxgowc4r8i5MGi2mV5WK60wnl+qYg7UPOEZkRNcnjl289cciQKcBYqmtKiH07g93LHn/0mr8PZzrtFURqMgB0DAcmh4pjt6/L9QegJ1R+c3KQ5SK+U9 ubuntu@node" > /home/ubuntu/.ssh/authorized_keys
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys

#Setup Hostname
hostnamectl set-hostname ${hostname}

# Install Kubernetes
swapoff -a
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system
apt-get update -y
apt-get install -y containerd
mkdir -p /etc/containerd
containerd config default | tee /etc/containerd/config.toml
sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
systemctl restart containerd
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update -y
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl containerd
systemctl enable kubelet.service
systemctl enable containerd.service

cd /usr/local/bin/
curl -o calicoctl -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.19.1/calicoctl" 
chmod +x calicoctl

apt-get install -y mysql-client

# # Install Docker
# apt-get update -y
# apt-get install -y ca-certificates curl gnupg
# install -m 0755 -d /etc/apt/keyrings
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# chmod a+r /etc/apt/keyrings/docker.gpg
# echo "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# apt-get update -y
# apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# usermod -a -G docker ubuntu
# docker run hello-world
# 
# # Initialize a swarm
# #docker swarn init

echo END