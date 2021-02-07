#!/bin/bash
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
