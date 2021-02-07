#!/bin/bash
for deb in docker.io cpu-checker jq kubelet kubeadm kubectl nfs-common open-iscsi;
do
  ver=$(apt-cache policy $deb | grep Installed | awk -F ': ' '{print $2}')
  if [ "$ver" == "(none)" ]; then
    echo "$deb installation failed"
  else
    echo "$deb installation successful"
  fi
done

docker-compose version > /dev/null
if [ $? -eq 0 ];then
  echo "docker-compose installation successful"
else
  echo "docker-compose installation failed"
fi

cat << EOF >/etc/docker/daemon.json
{
  "insecure-registries":["0.0.0.0/0"],
  "registry-mirrors":["http://cetccloud.com"]
}
EOF

source /opt/onestack/000-onestack-rc
local_ip=$(ip -o -4 addr list os.mgm | awk '{print $4}' | cut -d/ -f1 | head -1 )
if [ "${REPO_IPADDR}" != "${local_ip}" ];then
   systemctl daemon-reload
   systemctl restart docker
fi

apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet docker


