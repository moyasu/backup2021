#!/bin/bash

set -o errexit
#set -o nounset
set -o pipefail

if [ $# == 0 ]; then
  echo "Usage: $0 IPList"
  echo "$0 10.6.7.106 10.6.7.108 10.6.7.109"
  exit 1
fi

local_ip=$(ip -o -4 addr list os.mgm | awk '{print $4}' | cut -d/ -f1 | head -1 )

apt-get install -y chrony > /dev/null
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
cat ./templates/chrony_server.tpl > /etc/chrony/chrony.conf
systemctl restart chrony.service

cmd="echo 'server $local_ip iburst' >> /etc/chrony/chrony.conf;
     systemctl restart chrony.service;
     chronyd -q"

function SyncTime() {
  echo "Sync Time on ${host}"
  scp /etc/localtime $host:/etc/ > /dev/null
  ssh $host "apt-get install -y chrony > /dev/null"
  if [ "$host" != "$local_ip" ]; then
    scp templates/chrony_client.tpl $host:/etc/chrony/chrony.conf > /dev/null
    ssh -Tq $host "${cmd}" > /dev/null 2>&1
  fi
}


for host in $@;
do
  SyncTime $host &
done
wait

