#!/bin/bash

provision=/root/CPAC-config/Provisioning/cpac_provision.sh
chmod +x ${provision}
${provision} -p
source /etc/bash.bashrc
source activate cpac
${provision} -n "cpac"
/opt/afni/@update.afni.binaries -bindir /opt/afni
mv /root/bashrc /root/.bashrc
