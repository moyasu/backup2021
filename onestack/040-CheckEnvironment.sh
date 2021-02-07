#!/bin/bash


if [ $# == 0 ]; then
  echo "Usage: $0 IP1 IP2 IP3 ..."
  echo "e.g $0 10.6.7.106 10.6.7.108 10.6.7.109"
  exit 1
fi

if [ ! -d ./logs/040-CheckEnvironment ];then
  mkdir ./logs/040-CheckEnvironment/
fi

# ************ Check Network Reachable ********

declare -A gw_dict
for gw_type in "Mgm" "Int" "Stor" "Ext"; do
  gw_dict["${gw_type}_gw"]=`grep -r ${gw_type}NetGateway templates/NetworkInit.yaml | awk -F ': ' '{print $2}'`
done

function CheckNetworkReachable() {
  echo "Test ${host} network health"
  for gw_type in "Mgm" "Int" "Stor" "Ext"; do
    ssh root@${host} "ping -c 10 -w 1 -i 0.01 -q ${gw_dict["${gw_type}_gw"]}"
    if [ $? -ne 0 ]; then
      echo "Error. Host ${host} to ${gw_type} GateWay ${gw_dict["${gw_type}_gw"]} is not reachable!"
      exit 1
    fi
  done
}

for host in "$@"; do
  CheckNetworkReachable $host | tee -a /tmp/res.log &
done
grep -r Error /tmp/res.log > /dev/null
if [ $? -eq 0 ];then
  rm -rf /tmp/res.log
  exit 1
fi

# *******************************************

# ************  Check Host Kernel ************
function CheckHostKernel() {
  release=`ssh $host "uname -r"`
  ver=`echo ${release} | awk -F'-' '{print $1}'`
  if [[ ${ver} == "4.4.131" ]]; then
    echo "${host} kernel version is ${ver} - Good"
  else
    echo "Error ${host} kernel version is ${ver},
    Please check! (should be 4.4.131)"
    exit 1
  fi
}
for host in "$@"; do
  {
    CheckHostKernel $host | tee -a /tmp/res.log &
  }&
done
wait
grep -r Error /tmp/res.log > /dev/null
if [ $? -eq 0 ];then
  rm -rf /tmp/res.log
  exit 1
fi
wait
