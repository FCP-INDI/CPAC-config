#!/bin/bash

provision=/root/CPAC-config/Provisioning/cpac_provision.sh
chmod +x ${provision}
${provision} -p
export PATH=/usr/local/bin/miniconda/envs/cpac/bin:${PATH}
${provision} -n "cpac"
/opt/afni/@update.afni.binaries -bindir /opt/afni
mv /root/bashrc /root/.bashrc
