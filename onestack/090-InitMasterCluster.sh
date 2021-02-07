#!/bin/bash
set -o errexit
#set -o nounset
set -o pipefail

echo "Initialize hosts for Onestack, ..."

source ./000-onestack-rc 
echo ""
echo "----------------------------------"
echo "Step 01: Set Cluster Login free"
echo "----------------------------------"
./010-SyncSSHKeyAndConfig.sh ${MASTER_NODES[@]} ${WORKER_NODES[@]}

echo ""
echo "----------------------------------"
echo "Step 02: Set Cluster Hostname"
echo "----------------------------------"
./020-ConfigHostNames.sh

echo ""
echo "----------------------------------"
echo "Step 03: Set Cluster DNS"
echo "----------------------------------"
./030-SetDNS.sh

echo ""
echo "----------------------------------"
echo "Step 04: Check Cluster Environment"
echo "----------------------------------"
#./040-CheckEnvironment.sh ${MASTER_NODES[@]} ${WORKER_NODES[@]}

echo ""
echo "----------------------------------"
echo "Step 05: Set Cluster Swapoff"
echo "----------------------------------"
./050-TurnSwapOff.sh ${MASTER_NODES[@]} ${WORKER_NODES[@]}

echo ""
echo "----------------------------------"
echo "Step 06: Set Cluster Rp_filter"
echo "----------------------------------"
./055-SetRpFilter.sh ${MASTER_NODES[@]} ${WORKER_NODES[@]}

echo ""
echo "----------------------------------"
echo "Step 07: Set Cluster SyncTime"
echo "----------------------------------"
./060-SyncTime.sh ${MASTER_NODES[@]} ${WORKER_NODES[@]}

echo ""
echo "----------------------------------"
echo "Step 08: Install Cluster Packages"
echo "----------------------------------"
./070-ClusterNodePackages.sh

echo ""
echo "----------------------------------"
echo "Step 10: Check Repo Status"
echo "----------------------------------"
source /opt/onestack/templates/CheckHarbor.sh
if [ $? -ne 0 ]; then
  echo "Host ${host} check Harbor Failed" >> /dev/null 2>&1
  exit 1
fi

echo "--------------------------"
echo "Finished, please enjoy it."
echo "--------------------------"
