#!/bin/bash

cd /tmp
wget https://raw.githubusercontent.com/FCP-INDI/CPAC-config/master/Provisioning/cpac_provision.sh
chmod +x cpac_provision.sh
/tmp/cpac_provision.sh -p
/tmp/cpac_provision.sh -n "cpac"
rm /tmp/cpac_provision.sh
/opt/afni/@update.afni.binaries
