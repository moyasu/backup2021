#!/bin/bash

# Get physical network card name
MgmNetAdapterName=$(cat templates/NetworkInit.yaml | grep MgmNetAdapterName | awk -F ':' '{print $2}' | awk '$1=$1')
DataNetAdapterName=$(cat templates/NetworkInit.yaml | grep IntNetAdapterName | awk -F ':' '{print $2}'| awk '$1=$1')
IntNetAdapterName=$(cat templates/NetworkInit.yaml | grep HybNetAdapterName | awk -F ':' '{print $2}' | awk '$1=$1')

# Get management network configuration information
MgmAddr=$(cat templates/NetworkInit.yaml | grep MgmAddr | awk -F ':' '{print $2}'| awk '$1=$1')
MgmMask=$(cat templates/NetworkInit.yaml | grep MgmMask | awk -F ':' '{print $2}'| awk '$1=$1')
MgmNetGateway=$(cat templates/NetworkInit.yaml | grep MgmNetGateway | awk -F ':' '{print $2}'| awk '$1=$1')
MgmVlanId=$(cat templates/NetworkInit.yaml | grep MgmVlanId | awk -F ':' '{print $2}'| awk '$1=$1')

# Get Integrated  network configuration information
IntAddr=$(cat templates/NetworkInit.yaml | grep IntAddr | awk -F ':' '{print $2}'| awk '$1=$1')
IntMask=$(cat templates/NetworkInit.yaml | grep IntMask | awk -F ':' '{print $2}'| awk '$1=$1')

# Get storage network configuration information
StorVlanId=$(cat templates/NetworkInit.yaml | grep StorVlanId | awk -F ':' '{print $2}'| awk '$1=$1')
StorAddr=$(cat templates/NetworkInit.yaml | grep StorAddr | awk -F ':' '{print $2}'| awk '$1=$1')
StorMask=$(cat templates/NetworkInit.yaml | grep StorMask | awk -F ':' '{print $2}'| awk '$1=$1')

# Get floating network configuration information
ExtVlanId=$(cat templates/NetworkInit.yaml | grep ExtVlanId | awk -F ':' '{print $2}'| awk '$1=$1')
ExtAddr=$(cat templates/NetworkInit.yaml | grep ExtAddr | awk -F ':' '{print $2}'| awk '$1=$1')
ExtMask=$(cat templates/NetworkInit.yaml | grep ExtMask | awk -F ':' '{print $2}'| awk '$1=$1')

cat << EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

#auto $MgmNetAdapterName
#iface $MgmNetAdapterName inet manual
auto $MgmNetAdapterName
iface $MgmNetAdapterName inet static
    address $MgmAddr
    netmask $MgmMask
    gateway $MgmNetGateway
    #vlan-raw-device $MgmNetAdapterName

auto $DataNetAdapterName
iface $DataNetAdapterName inet static
    address $IntAddr
    netmask $IntMask
   
auto $IntNetAdapterName
iface $IntNetAdapterName inet manual

auto $IntNetAdapterName.$StorVlanId
iface $IntNetAdapterName.$StorVlanId inet static
    address $StorAddr
    netmask $StorMask
    vlan-raw-device $IntNetAdapterName

auto $IntNetAdapterName.$ExtVlanId
iface $IntNetAdapterName.$ExtVlanId inet static
    address $ExtAddr
    netmask $ExtMask
    vlan-raw-device $IntNetAdapterName
EOF

cat << EOF > /etc/network/interfaces.d/up-rename-card
#!/bin/bash
ip add show $MgmNetAdapterName > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down $MgmNetAdapterName
  ip link set dev $MgmNetAdapterName name os.mgm
  ip link set up os.mgm
fi
ip add show $DataNetAdapterName > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down $DataNetAdapterName
  ip link set dev $DataNetAdapterName name ens2
  ip link set up ens2
fi
ip add show $IntNetAdapterName.$StorVlanId > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down $IntNetAdapterName.$StorVlanId
  ip link set dev $IntNetAdapterName.$StorVlanId name os.stor
  ip link set up os.stor
fi
ip add show $IntNetAdapterName.$ExtVlanId > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down $IntNetAdapterName.$ExtVlanId
  ip link set dev $IntNetAdapterName.$ExtVlanId name os.ext
  ip link set up os.ext
fi
ip route | grep default
if [ \$? -ne 0 ];then
  route add default gw $MgmNetGateway 
fi
EOF

cat << EOF >  /etc/network/if-down.d/down-rename-card
#!/bin/bash
ip add show os.mgm > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down os.mgm
  #ip link set dev os.mgm name $MgmNetAdapterName
  ip link set dev os.mgm name $MgmNetAdapterName
  ip link set up $MgmNetAdapterName
fi
ip add show ens2 > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down ens2
  ip link set dev  ens2 name $DataNetAdapterName
  ip link set up $DataNetAdapterName
fi
ip add show os.stor > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down os.stor
  ip link set dev  os.stor name $IntNetAdapterName.$StorVlanId
  ip link set up $IntNetAdapterName.$StorVlanId
fi
ip add show os.ext > /dev/null 2>&1
if [ \$? -eq 0 ];then
  ip link set down os.ext
  ip link set dev  os.ext name $IntNetAdapterName.$ExtVlanId
  ip link set up $IntNetAdapterName.$ExtVlanId
fi
EOF
chmod +x /etc/network/if-down.d/down-rename-card
chmod +x /etc/network/interfaces.d/up-rename-card
echo "ExecStartPost=/bin/bash -c /etc/network/interfaces.d/up-rename-card" >> /lib/systemd/system/networking.service
