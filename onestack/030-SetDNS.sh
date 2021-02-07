#!/bin/bash


#The script initializes the hosts files of the three master nodes by default. 
#If you need to synchronize other nodes, 
#you need to manually add parameters when executing the script.
#e.g ./030-SetDNS.sh workerNodeIpAdd1 workerNodeIpAdd2 ...

set -o errexit
#set -o nounset
set -o pipefail

if [ ! -d ./logs/030-SetDNS ];then
  mkdir ./logs/030-SetDNS/
fi


source 000-onestack-rc
echo "127.0.1.1 HOSTNAME" > /tmp/dns
echo "127.0.0.1 localhost localhost.localdomain localhost4local host4.localdomain4" >> /tmp/dns
echo "::1 localhost6 localhost6.localdomain6" >> /tmp/dns

echo "$REPO_IPADDR cetccloud.com" >> /tmp/dns
echo "$K8SHA_VIP ${K8SHA_VHOST}" >> /tmp/dns


for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  HostName=$(ssh $host 'hostname')
  echo "$host ${HostName}" >> /tmp/dns
done

echo "Cluster DNS:"
echo "----------------------"
cat /tmp/dns
echo "----------------------"

function SetDnsRecords() {
  echo "set DNS records on ${host}"
  scp /tmp/dns $host:/tmp/hosts >> /dev/null 2>&1
  HostName=$(ssh $host 'hostname')
  ssh $host "sed -i 's/HOSTNAME/${HostName}/g' /tmp/hosts"
  ssh $host "mv /tmp/hosts /etc/hosts"
  ssh $host "cat /etc/hosts" >> ./logs/030-SetDNS/$host.log
}

for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  SetDnsRecords $host &
done
wait
rm -f /tmp/dns

