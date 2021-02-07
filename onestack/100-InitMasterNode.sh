#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

if [ $# -ne 2 ]; then
  echo "Usage: $0 HostName Address"
  echo "$0  onestack02 10.6.7.107"
  exit 1
fi

host_name=${1}
ip_addr=${2}

source ./000-onestack-rc 
echo "Initialize hosts for Onestack, ..."
echo "*************************"
./010-SyncSSHKeyAndConfig.sh ${MASTER_NODES[@]} ${WORKER_NODES[@]}
echo "*************************"
./025-SetHostName.sh ${host_name} ${ip_addr}
echo "*************************"
./030-SetDNS.sh
echo "*************************"
./040-CheckEnvironment.sh ${ip_addr}
echo "*************************"
./050-TurnSwapOff.sh ${ip_addr}
echo "*************************"
./055-SetRpFilter.sh ${ip_addr}
echo "*************************"
./065-SetSyncTime.sh ${ip_addr}
echo "*************************"
./070-MasterNodePackages.sh ${ip_addr}
echo "*************************"
echo "Finished, please enjoy it."
