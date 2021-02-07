#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [ $# == 0 ]; then
  echo "Usage: $0 IPList"
  echo "$0 10.6.7.106 10.6.7.108 10.6.7.109"
  exit 1
fi

if [ ! -d ./logs/065-SyncTime  ];then
  mkdir ./logs/065-SyncTime/
fi

local_ip=$(ip -o -4 addr list os.mgm | awk '{print $4}' | cut -d/ -f1 | head -1 )

function SyncClientTime() {
  echo "Sync Time on ${host}"
  scp /etc/localtime $host:/etc/ > /dev/null
  ssh $host "apt-get install -y chrony > /dev/null"
  scp templates/chrony_client.tpl $host:/etc/chrony/chrony.conf > /dev/null
  ssh $host "echo 'server $local_ip iburst' >> /etc/chrony/chrony.conf && \
         systemctl restart chrony.service && \
         chronyd -q " > /dev/null 2>&1
}

for host in "$@";
do
  SyncClientTime $host &
done
wait

