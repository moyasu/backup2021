#!/bin/bash

source 000-onestack-rc

for deb in docker.io cpu-checker jq kubelet kubeadm kubectl nfs-common open-iscsi;
do 
  ver=$(apt-cache policy $deb | grep Installed | awk -F ': ' '{print $2}')
  if [ "$ver" == "(none)" ]; then
    echo "$deb is not installed, installing..."        
    if [ "$deb" == "kubelet" ] || [ "$deb" == "kubeadm" ] || [ "$deb" == "kubectl" ];then
      apt-get install "$deb=1.18.6-00" -y
    else
      apt-get install $deb -y
    fi

  else
    if [ "$deb" == "kubelet" ] || [ "$deb" == "kubeadm" ] || [ "$deb" == "kubectl" ];then
      if [ "$ver" == "1.18.6-00"  ];then
        echo "$deb is right installed,skip."
      else
        echo "ERROR, Our deployment Depends: $deb (= 1.18.6-00) but $ver has been installed, please fix it manually !!"
        exit 1 
      fi
    else
      echo "$deb is installed,skip."
    fi
  fi
done

