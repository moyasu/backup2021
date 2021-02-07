#!/bin/bash

set -o errexit
#set -o nounset
set -o pipefail

source 000-onestack-rc

if [ ! -d ./logs/080-WorkerNodePackages ];then
  mkdir ./logs/080-WorkerNodePackages/
fi

for host in ${EXTRA_WORKER_NODES[@]};
do
{
  echo "Install packages on $host"
  ssh -Tq $host "cd /opt/onestack/; source ./templates/ClusterNodePackages.sh" >> ./logs/080-WorkerNodePackages/$host.log 2>&1
}&
done
wait

for host in ${EXTRA_WORKER_NODES[@]};
do
  echo ""
  echo "Verify packages on $host"
  ssh -Tq $host "cd /opt/onestack/; source ./templates/VerifyPackages.sh"
done

