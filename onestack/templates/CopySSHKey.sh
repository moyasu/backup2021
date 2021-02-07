#!/bin/bash
set -o errexit
#set -o nounset
#set -o pipefail

source /opt/onestack/000-onestack-rc

if ! (hash ssh-copy-id); then
  echo "ERROR: ssh-copy-id command not found: Aborting" 2>&2
  exit 2
fi

function GenSSHKey() {
  # Delete old id_rsa
  rm -f ~/.ssh/id_rsa
  rm -f ~/.ssh/id_rsa.pub
  # Generate new id_rsa.pub
  expect -c "
    set timeout -1;
    spawn ssh-keygen -t rsa;
    expect {
      */root/.ssh/id_rsa* {send -- \r;exp_continue;}
      *passphrase):*      {send -- \r;exp_continue;}
      *again:*            {send -- \r;exp_continue;}
      eof                 {exit 0;}
    };"
}

echo "apt install expect ...."
apt-get install -y expect
GenSSHKey
for host in ${MASTER_NODES[@]} ${WORKER_NODES[@]} ${EXTRA_WORKER_NODES[@]};
do
  {
    echo "ssh-copy-id to $host"
    expect -c "set timeout -1;
      spawn ssh-copy-id $host;
      expect {
        *(yes/no)* {send -- yes\r;exp_continue;}
        *assword:* {send -- ${CLUSTER_PASSWD}\r;exp_continue;}
        eof        {exit 0;}
    }";
  }&
done
wait
