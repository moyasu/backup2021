#!/bin/bash

# check and upgrade Linux Kernel to 5.4.0

source /opt/onestack/000-onestack-rc

if [ ! -d ./logs/005-UpgradeKernel ];then
  mkdir ./logs/005-UpgradeKernel/
fi

# ************  Check Host Alive ************
echo "--------------------------"
echo "Step1: Check Host Alive"
echo "--------------------------"
function checkhost() {
  ping $host -c 10 -w 1 -i 0.01 -q > /dev/null
  if [ $? -eq 0 ];then
    echo "$host is alive !"
  else
    echo "$host is unreachable ！
    Error. Please check !"
  fi
}

for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  checkhost $host | tee -a /tmp/res.log &
done
wait
grep -r Error /tmp/res.log > /dev/null
if [ $? -eq 0 ];then
  rm -rf /tmp/res.log
  exit 1
fi
# ******************************************

echo ""
echo "--------------------------"
echo "Step2: Setting Repo"
echo "--------------------------"
./templates/SetRepo.sh
if [ $? -ne '0' ];then echo "Set repo failed, Please check !";exit 1; fi

echo ""
echo "--------------------------"
echo "Step3: Setting Password Free Login"
echo "--------------------------"
./templates/CopySSHKey.sh > /dev/null 2>&1
if [ $? -ne '0' ];then echo "Set login free failed, Please check !";exit 1;else echo "Set login free success !"; fi

for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  if [ "$host" == "${REPO_IPADDR}" ];then
    scp ./000-onestack-rc ${REPO_IPADDR}:/opt/onestack > /dev/null 2>&1
    ssh ${REPO_IPADDR} "source /opt/onestack/templates/SetRepo.sh;apt-get install jq -y" > /dev/null 2>&1
    if [ $? -ne '0' ];then echo "Repo Node install jq failed, Please check !";exit 1; fi
  fi
done

# *************   Update Kernel   **********
echo ""
echo "--------------------------"
echo "Step4: Update Kernel"
echo "--------------------------"

local_ip=$(ip -o -4 addr list os.mgm | awk '{print $4}' | cut -d/ -f1 | head -1 )
function UpdateKernel() {
  scp ./000-onestack-rc $host:/opt/onestack >> ./logs/005-UpgradeKernel/$host.log 2>&1
  ssh root@$host "source /opt/onestack/templates/SetRepo.sh" >> ./logs/005-UpgradeKernel/$host.log 2>&1
  if [ $? -ne '0' ];then echo "Set Repo failed on $host , Please check !";exit 1; fi
  wait
  release=`ssh $host "uname -r"`
  ver=`echo ${release} | awk -F'-' '{print $1}'`
  if [[ ${ver} == "5.4.0" ]]; then
    echo "${host} kernel version is ${ver} - Good"
  else
    echo "${host} kernel version is ${ver}, begin to upgrade!"
    ssh root@$host "wget http://${REPO_IPADDR}:31011/smallcloud2/master/kylin-image-4.4.131-20191129-generic_4.4.131-20191129.kylin_arm64.deb; dpkg -i kylin-image-4.4.131-20191129-generic_4.4.131-20191129.kylin_arm64.deb"
    if [ $? -eq '0' ];then
      if [ "$host" != "${local_ip}" ];then
        echo "$host kernel update success ! rebooting ..."
        ssh $host "reboot" > /dev/null 2>&1
      else
	echo "The kernel of this machine(${local_ip}) has been updated. Please restart manually later"
      fi
    else
      echo "$host kernel update failed! Error. Please check !"
    fi
  fi
}

for host in  ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  UpdateKernel $host | tee -a /tmp/res.log &
done
wait

grep -r Error /tmp/res.log > /dev/null
if [ $? -eq 0 ];then
  rm -rf /tmp/res.log
  exit
fi
# ******************************************
