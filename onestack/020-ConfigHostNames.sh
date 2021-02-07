#!/bin/bash

#This script is only used to configure the hostname of the three master nodes

set -o errexit
#set -o nounset
set -o pipefail

if [ ! -d ./logs/020-ConfigHostNames ];then
  mkdir ./logs/020-ConfigHostNames/
fi

source 000-onestack-rc

number=1
for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]};
do
  suffix=$(printf "%02d" $number)
  echo "set hostname of $host to ${COMMON_HOSTNAME}${suffix}"
  ssh $host "hostnamectl set-hostname ${COMMON_HOSTNAME}${suffix}"
  ssh $host "cat /etc/hostname" >> ./logs/020-ConfigHostNames/$host.log 2>&1
  number=`expr $number + 1`;
done
