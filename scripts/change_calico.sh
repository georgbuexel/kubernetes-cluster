#!/bin/bash -ex
##############################################Calico settings (must perform these if you have Windows worker nodes)##################
#1 - Install "calicococtl" on one or more nodes: "https://docs.projectcalico.org/getting-started/clis/calicoctl/install"
# sudo -i
# cd /usr/local/bin/
# curl -o calicoctl -O -L  "https://github.com/projectcalico/calicoctl/releases/download/v3.19.1/calicoctl" 
# chmod +x calicoctl
# exit

#2 - Disable "IPinIP":  
calicoctl get ipPool default-ipv4-ippool  -o yaml > ippool.yaml
# nano ippool.yaml #Set: "ipipMode: Never", was "ipipMode: Always"
sed -i 's/ipipMode: Always/ipipMode: Never/g' ippool.yaml
calicoctl apply -f ippool.yaml

kubectl get felixconfigurations.crd.projectcalico.org default  -o yaml -n kube-system > felixconfig.yaml
# nano felixconfig.yaml #Set: "ipipEnabled: false", was "ipipEnabled: true"
# sed -i 's/ipipEnabled: true/ipipEnabled: false/g' felixconfig.yaml
echo -e "  ipipEnabled: false" >> felixconfig.yaml
kubectl apply -f felixconfig.yaml

#3 - Configure strict affinity for clusters using Calico networking 
# For Linux control nodes using Calico networking, strict affinity must be set to true. 
# This is required to prevent Linux nodes from borrowing IP addresses from Windows nodes:"

calicoctl ipam configure --strictaffinity=true

# Alternatively you ca use
# kubectl patch ipamconfigurations default --type merge --patch='{"spec": {"strictAffinity": true}}'
