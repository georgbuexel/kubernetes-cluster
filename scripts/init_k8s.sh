#!/bin/bash -ex
# Initialize a k8s control plane node

# sudo kubeadm init
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
wget https://raw.githubusercontent.com/projectcalico/calico/master/manifests/calico.yaml
kubectl apply -f calico.yaml
kubeadm token create --print-join-command | tee /tmp/join_worker_command
