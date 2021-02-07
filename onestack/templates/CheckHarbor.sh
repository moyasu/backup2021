#!/bin/bash

#set -o errexit
set -o nounset
set -o pipefail

#Check the Harbor Status
docker pull cetccloud.com:31010/v0.1/busybox:latest > /dev/null 2>&1
if [ $? == "0" ];then 
  echo "Harbor Test: success"
  docker rmi -f cetccloud.com:31010/v0.1/busybox:latest > /dev/null 2>&1
else 
  echo "Harbor Test: failed"
  exit 1
fi
    
