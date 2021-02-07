#!/bin/bash

set -o errexit
#set -o nounset
set -o pipefail

if [ $# == 0 ]; then
  echo "Usage: $0 IPList"
  echo "$0  10.6.7.106 10.6.7.108 10.6.7.109"
  exit 1
fi

function Swapoff() {
  echo "run 'swapoff -a' on $host"
  ssh $host "swapoff -a"
  if [ $(ssh $host "grep -c 'swap' /etc/fstab") -eq '0' ];then
    echo "no swap mount on $host"
  else
    ssh $host "sed -i '/swap/s/.*/#&/' /etc/fstab"
    echo "Annotated swap mount on $host"
  fi
}

for host in "$@";
do
  Swapoff $host &
done
wait

