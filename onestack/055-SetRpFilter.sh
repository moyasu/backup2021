#!/bin/bash

set -o errexit
#set -o nounset
set -o pipefail

if [ $# == 0 ]; then
  echo "Usage: $0 IPList"
  echo "$0  10.6.7.106 10.6.7.108 10.6.7.109"
  exit 1
fi

cmd="echo 2 > /proc/sys/net/ipv4/conf/default/rp_filter;
      echo 2 > /proc/sys/net/ipv4/conf/all/rp_filter;
      echo 'net.ipv4.conf.default.rp_filter = 2' >> /etc/sysctl.conf;
      echo 'net.ipv4.conf.all.rp_filter = 2' >> /etc/sysctl.conf"
for host in "$@"; do
  {
    echo "Set rp_filter on ${host}"
    ssh $host "${cmd}"
   }&
done
wait
