#!/bin/bash
# link_common_resources.sh
# Generates hard links to all of the files in the common resources directories to all of the individual Docker
# testing environments.

base=/tdata/Configs/Dockerfiles

# Define versions of CentOS and Ubuntu used.
centos_vers=(5 6 7)
ubuntu_vers=(12.04 14.04 16.04 16.10)

# Make directories if they don't already exist and then link in files.
for c in ${centos_vers[@]}
do
	if [ ! -d ${base}/CentOS/${c} ];
	then
		mkdir -p ${base}/CentOS/${c}
	fi
	ln ${base}/Common_Resources/* ${base}/CentOS/${c} 2> /dev/null
done

for u in ${ubuntu_vers[@]}
do
	if [ ! -d ${base}/Ubuntu/${u} ];
	then
		mkdir -p ${base}/Ubuntu/${u}
	fi
	ln ${base}/Common_Resources/* ${base}/Ubuntu/${u} 2> /dev/null
done
