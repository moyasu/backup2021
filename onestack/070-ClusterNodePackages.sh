#!/bin/bash

set -o errexit
#set -o nounset
set -o pipefail

source /opt/onestack/000-onestack-rc

if [ ! -d ./logs/070-ClusterNodePackages ];then
  mkdir ./logs/070-ClusterNodePackages/
fi


for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
{
  echo "Install packages on $host"
  ssh -Tq $host "cd /opt/onestack/; source ./templates/ClusterNodePackages.sh" >> ./logs/070-ClusterNodePackages/$host.log 2>&1
}&
done
wait

for host in ${MASTER_NODES[@]};
do
{
  ssh -Tq $host "source /opt/onestack/templates/SetupKeepalived.sh; wget -P /usr/local/bin http://${REPO_IPADDR}:31011/smallcloud2/master/docker-compose -O docker-compose;chmod +x /usr/local/bin/docker-compose" > /dev/null 2>&1
}&
done
wait


for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  echo ""
  echo "Verify packages on $host"
  ssh -Tq $host "cd /opt/onestack/; source ./templates/VerifyPackages.sh"
done

