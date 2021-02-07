#!/bin/bash

# Install docker-ce
if [ -f /opt/docker-ce.tar.gz ];then
  cd /opt && tar -xzvf docker-ce.tar.gz
  if [ $? -ne '0' ];then echo "decompression failed, Please check !";exit 1; fi
  apt-key add ./docker-ce/docker-ce.pub
  cat << EOF > /etc/apt/sources.list
deb file:/opt/docker-ce  /
EOF
  apt-get update && apt-get install docker-ce --no-install-recommends -y
  if [ $? -ne '0' ];then echo "Install docker-ce failed, Please check !";exit 1; fi

  cat << EOF >/etc/docker/daemon.json
{
"insecure-registries":["0.0.0.0/0"],
"registry-mirrors":["http://cetccloud.com"]
}
EOF
  systemctl daemon-reload
  systemctl restart docker
  cp /opt/docker-ce/docker-compose /usr/local/bin/
else
  echo "docker-ce.tar.gz non-existent"
  exit 1 
fi

# Setup offline repo
if [ -f /opt/harbor.tar.gz ];then
  cd /opt && tar -xzvf harbor.tar.gz
  if [ $? -ne '0' ];then echo "decompression failed, Please check !";exit 1; fi
  cd harbor && docker load -i harbor.v2.0.1.tar.gz
  if [ $? -ne '0' ];then echo "docker load failed, Please check !";exit 1; fi
  ./prepare && docker-compose up -d
  if [ $? -ne '0' ];then echo "Setup Harbor failed, Please check !";exit 1; fi
  docker pull cetccloud.com:31010/openstackhelm_repo/osh-repo:v1.0
  if [ $? -ne '0' ];then echo "Get osh-repo image failed, Please check !";exit 1; fi
  docker run -itd --name osh-repo -p 31011:80 cetccloud.com:31010/openstackhelm_repo/osh-repo:v1.0 ./start.sh
  if [ $? -ne '0' ];then echo "Setup osh-repo failed, Please check !";exit 1; fi
else
  echo "harbor.tar.gz non-existent"
  exit 1
fi

# Set Harbor boot automatically

cat << EOF > /etc/systemd/system/harbor.service
[Unit]
Description=/etc/rc.local Compatibility
ConditionPathExists=/etc/rc.local
 
[Service]
Type=forking
ExecStart=/etc/rc.local start
TimeoutSec=0
StandardOutput=tty
RemainAfterExit=yes
SysVStartPriority=99
 
[Install]
WantedBy=multi-user.target
EOF

cat << EOF > /etc/rc.local 
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.
cd /opt/harbor/ && docker-compose up -d
docker start osh-repo
EOF

sudo chmod 755 /etc/rc.local
sudo systemctl enable rc-local >> /dev/null 2>&1

sudo systemctl start harbor.service
sudo systemctl status harbor.service
