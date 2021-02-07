#! /bin/bash

source /opt/onestack/000-onestack-rc

# Set Osh-repo
echo "deb http://$REPO_IPADDR:$REPO_PORT/smallcloud2/apt /" > /etc/apt/sources.list

# Add this DNS just for test temporarily, /etc/hosts will be reset in 030-SetDNS.sh
sed -i "/cetccloud.com/d" /etc/hosts
echo "$REPO_IPADDR  cetccloud.com" >> /etc/hosts
# Check the Osh-repo Status
curl -fsSL http://cetccloud.com:$REPO_PORT/smallcloud2/apt/apt-key.pub | apt-key add - > /dev/null 2>&1
if [ $? == "0" ];then 
  echo "Apt-key Test: success"
else 
  echo "Apt-key Test: failed"
  exit 1
fi
if [ -z "$(apt-get update | grep "Err")" ];then 
  echo "Osh-repo Test: success"
else 
  echo "Osh-repo Test: failed"
  exit 1
fi


