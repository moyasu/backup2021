#!/bin/bash

# The script do 3 things:
# 1. Set each node's apt repo,
# 2. login free of three master nodes,
# 3. sync deploy scripts from deploy node to other nodes.

# If you need to add a worker node to login free with them ,
# you can add the worker node address after the script

#set -o nounset
set -o pipefail

if [ $# == 0 ]; then
  echo "Usage: $0 IP1 IP2 IP3 ..."
  echo "e.g $0 10.6.7.106 10.6.7.108 10.6.7.109"
  exit 1
fi

if [ ! -d ./logs/010-SyncSSHKeyAndConfig ];then
  mkdir ./logs/010-SyncSSHKeyAndConfig/
fi

# ************  Check Host Alive ************
for host in "$@";
do
  ping $host -c 10 -w 1 -i 0.01 -q >> ./logs/010-SyncSSHKeyAndConfig/$host.log 2>&1
  if [ $? -eq 0 ];then
    echo "$host is alive !"
  else
    echo "$host is unreachable ！
    Please check the host($host) network"
    exit 1
  fi
done
# *******************************************

local_ip=$(ip -o -4 addr list os.mgm | awk '{print $4}' | cut -d/ -f1 | head -1 )

./templates/SetRepo.sh
if [ $? -ne '0' ];then echo "Set repo failed, Please check !";exit 1; fi

echo "Unauthorize SSH on $local_ip"
./templates/CopySSHKey.sh >> ./logs/010-SyncSSHKeyAndConfig/${local_ip}.log
if [ $? -ne 0 ];then
  echo "exec ./templates/CopySSHKey.sh failed"
  exit 1
fi

for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  if [ "$host" == "${REPO_IPADDR}" ];then
    scp ./000-onestack-rc $${REPO_IPADDR}:/opt/onestack > /dev/null 2>&1
    ssh ${REPO_IPADDR} "source /opt/onestack/templates/SetRepo.sh;apt-get install jq -y" > /dev/null 2>&1
    if [ $? -ne '0' ];then echo "Repo Node install jq failed, Please check !";exit 1; fi
  fi
done


function SetAuthorizeLogin() {
  if [ "$host" != "$local_ip" ];then
    # copy config from deploy node to other nodes and set authorize login
    echo "Copy Onestack config from local server(${local_ip}) to ${host}"
    scp ./000-onestack-rc $host:/opt/onestack > /dev/null
    echo "Unauthorize SSH on $host"
    ssh -Tq $host "cd /opt/onestack/; ./templates/CopySSHKey.sh;./templates/SetRepo.sh" >> ./logs/010-SyncSSHKeyAndConfig/$host.log 2>&1
  fi
}

for host in "$@";
do
  SetAuthorizeLogin $host &
done
wait
