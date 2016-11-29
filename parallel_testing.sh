#!/bin/bash

if [ -z $1 ]
then
	echo "Script requires a C-PAC branch be specified as the first argument."
	exit 1
fi

BRANCH=$1
DOCKERBASE=/tdata/Configs/Dockerfiles
DISTROS=("Ubuntu" "CentOS")
UBUNTU_VERS=("12.04" "14.04" "16.04" "16.10")
CENTOS_VERS=("5 6 7")
PARFILE=${DOCKERBASE}/test_commands.txt

for DISTRO in ${DISTROS[@]}
do
	if [ ${DISTRO} == 'Ubuntu' ] 
	then 
		for VER in ${UBUNTU_VERS[@]}
		do
			BUILDDIR=${DOCKERBASE}/${DISTRO}/${VER}
			echo "docker build ${BUILDDIR} --build-arg branch=${BRANCH} -t ubuntu:test_${VER} 2> ${BUILDDIR}/err.out > ${BUILDDIR}/std.out &" >> ${PARFILE}
		done
	elif [ ${DISTRO} == 'CentOS' ] 
	then 
		for VER in ${CENTOS_VERS[@]}
		do
			BUILDDIR=${DOCKERBASE}/${DISTRO}/${VER}
			echo "docker build ${BUILDDIR} --build-arg branch=${BRANCH} -t centos:test_${VER} 2> ${BUILDDIR}/err.out > ${BUILDDIR}/std.out &" >> ${PARFILE}
		done
	fi
done

parallel < ${PARFILE}
rm ${PARFILE}
