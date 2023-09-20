#!/bin/bash
 
while [ ! -f /tmp/join_worker_command ]; do
  echo -e "\033[1;36mWaiting for cluster setup..."
  sleep 1
done
 