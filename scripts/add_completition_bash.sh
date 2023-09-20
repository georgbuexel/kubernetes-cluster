#!/bin/bash -ex
# Add bash completition for kubectl
sudo apt-get install -y bash-completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
source ~/.bashrc