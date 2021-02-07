#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

echo "Initialize hosts for Onestack, ..."

source ./000-onestack-rc 
echo "*************************"
./010-SyncSSHKeyAndConfig.sh ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]}
echo "*************************"
i=0
while [ $i -lt ${#EXTRA_WORKER_NODES[@]} ]; do
  host_name=${EXTRA_WORKER_HOSTS[i]}
  ip_addr=${EXTRA_WORKER_NODES[i]}

  ./025-SetHostName.sh ${host_name} ${ip_addr}
  echo "*************************"
  ((++i))
done
./030-SetDNS.sh
echo "*************************"
./040-CheckEnvironment.sh ${EXTRA_WORKER_NODES[@]}
echo "*************************"
./050-TurnSwapOff.sh ${EXTRA_WORKER_NODES[@]}
echo "*************************"
./055-SetRpFilter.sh ${EXTRA_WORKER_NODES[@]}
echo "*************************"
./065-SetSyncTime.sh ${EXTRA_WORKER_NODES[@]}
echo "*************************"
./080-WorkerNodePackages.sh
echo "*************************"
echo "Finished, please enjoy it."
