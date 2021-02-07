#!/bin/bash

wget -O keepalived.tar.gz http://cetccloud.com:31011/smallcloud2/master/keepalived.tar.gz > /dev/null 2>&1
if [ $? -ne 0 ];then
  echo "Failed to pull keepalived"
  exit
fi

tar -xzvf keepalived.tar.gz -C /usr/local/

sudo mkdir -p /etc/keepalived
sudo ln -s /usr/local/keepalived/sbin/keepalived /usr/sbin/
sudo ln -s /usr/local/keepalived/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf
sudo ln -s /usr/local/keepalived/etc/sysconfig/keepalived /etc/default/keepalived

cat << EOF > /lib/systemd/system/keepalived.service
[Unit]
Description=Keepalive Daemon (LVS and VRRP)
After=syslog.target network-online.target
Wants=network-online.target
# Only start if there is a configuration file
ConditionFileNotEmpty=/etc/keepalived/keepalived.conf

[Service]
Type=forking
KillMode=process
# Read configuration variable file if it is present
EnvironmentFile=-/etc/default/keepalived
ExecStart=/usr/sbin/keepalived $KEEPALIVED_OPTIONS
ExecReload=/bin/kill -HUP $MAINPID

[Install]
WantedBy=multi-user.target
EOF
mkdir -p /etc/keepalived
chmod 755 /usr/sbin/keepalived
sudo ln -s /lib/systemd/system/keepalived.service /etc/systemd/system/multi-user.target.wants/keepalived.service
sudo systemctl start keepalived
sudo systemctl status keepalived
sudo systemctl enable keepalived
