#!/bin/bash

#This script can be used to configure the hostname of any node

set -o errexit
#set -o nounset
set -o pipefail

if [ $# -ne 2 ]; then
    echo "Usage: $0 hostname address"
    echo "$0  onestack04 10.6.7.109"
    exit 1
fi


echo "set hostname of ${2} to ${1}"
ssh ${2} "hostnamectl set-hostname ${1}"
