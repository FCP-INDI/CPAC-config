#! /bin/bash
# 
# cpac_provision_trusty64.sh
# Author(s): Daniel Clark, John Pellman
# Desc: A script to provision resources to a Vagrant/Virtualbox VM that will be then used to test C-PAC.
# Based off cpac_install.sh
# 
##### Get system info and set variables #####
# --- Create env vars instantiation script ---
# Source env vars
CPAC_ENV=/etc/profile.d/cpac_env.sh
touch $CPAC_ENV
source ~/.bashrc
source $CPAC_ENV
echo '########## CHECKING SYSTEM INFO AND SOFTWARE... ##########'
# --- Check for pre-existing software ---
which flirt && FSLFLAG=1 || FSLFLAG=0
which afni && AFNIFLAG=1 || AFNIFLAG=0
which ANTS && ANTSFLAG=1 || ANTSFLAG=0
which c3d && C3DFLAG=1 || C3DFLAG=0
NIPYPEFLAG=`python -c 'import nipype; print nipype.__version__' 2> /dev/null | grep -c 0.9.2` 
# --- Gets system architecture and sets file names for downloads accordingly ---
ARCHITECTURE=$(uname -p)
AFNI_DOWNLOAD=linux_openmp
case $ARCHITECTURE in
    x86_64 )
	AFNI_DOWNLOAD=linux_openmp_64
    	C3D_DOWNLOAD=c3d-0.8.2-Linux-x86_64
	;;
    i386 )
    	C3D_DOWNLOAD=c3d-0.8.2-Linux-i386
	;;
    i686 )
	C3D_DOWNLOAD=c3d-0.8.2-Linux-i686
	;;
esac
##### Acquire yum/aptitude-supported packages and dependencies #####
echo '########## UPDATING SOFTWARE... ##########'
# --- Ensure software is up-to-date ---
apt-get update
apt-get upgrade -y
# --- Install other utilities/libraries ---
# Git is needed for version control of source code (ANTs)
# Make is needed to compile source code (cmake, ANTs)
# Unzip is needed to unarchive zip files
# CPAC GUI needs libcanberra-gtk module
# AFNI (afni itself) needs: libxp6, netpbm. AFNI tools (e.g. 3dSkullStrip) need: libglu1, gsl-bin
# CMAKE and ANTs require zlib1g-dev to build latest ANTs from source
echo '---------- ACQUIRING NEEDED UTILITIES/LIBRARIES... ----------'
apt-get install -y cmake git make unzip libcanberra-gtk-module libxp6 netpbm libglu1 gsl-bin zlib1g-dev
# --- Install python package ---
echo '---------- ACQUIRING PYTHON DEPENDENCIES... ----------'
apt-get install -y python-numpy python-scipy python-matplotlib python-networkx python-traits python-wxgtk2.8 python-yaml python-jinja2 python-lockfile python-pygraphviz python-nibabel python-nose cython ipython
# --- Sun Grid Engine compatibility (uncomment if you want SGE compatibility) ---
#apt-get install -y libmotif4 nfs-common nfs-kernel-server
#
##### Install needed packages #####
echo '########## INSTALLING SOFTWARE TOOLS... ##########'
#--- Install Nipype 0.9.2 ---
if [ $NIPYPEFLAG -eq 0 ]
then
    echo '---------- INSTALLING NIPYPE... ----------'
    cd /tmp
    git clone -b 0.10.0 https://github.com/nipy/nipype.git
    cd nipype
    python setup.py install
fi
# --- Install FSL ---
if [ $FSLFLAG -eq 0 ]
then
    echo '---------- INSTALLING FSL... ----------'
    wget -O- http://neuro.debian.net/lists/$(lsb_release -cs).us-nh.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
    apt-key adv --recv-keys --keyserver pgp.mit.edu 2649A5A9
    apt-get update
    apt-get install -y fsl-5.0-complete
    FSLDIR=/usr/share/fsl/5.0
    echo '# Path to FSL' >> $CPAC_ENV
    echo 'FSLDIR=/usr/share/fsl/5.0' >> $CPAC_ENV
    echo '. ${FSLDIR}/etc/fslconf/fsl.sh' >> $CPAC_ENV
    echo 'PATH=${FSLDIR}/bin:${PATH}' >> $CPAC_ENV
    echo 'export FSLDIR PATH' >> $CPAC_ENV
fi
# --- Install AFNI ---
if [ $AFNIFLAG -eq 0 ]
then
    echo '---------- INSTALLING AFNI... ----------'
    cd /tmp
    wget --no-check-certificate https://afni.nimh.nih.gov/pub/dist/tgz/${AFNI_DOWNLOAD}.tgz
    tar xfz ${AFNI_DOWNLOAD}.tgz
    mv $AFNI_DOWNLOAD /opt/afni
    echo '# Path to AFNI' >> $CPAC_ENV
    echo 'export PATH=/opt/afni:$PATH' >> $CPAC_ENV
    echo 'export DYLD_FALLBACK_LIBRARY_PATH=/opt/afni' >> $CPAC_ENV
fi
# --- Install ANTs ---
if [ $ANTSFLAG -eq 0 ]
then
    echo '---------- INSTALLING ANTs... ----------'
    cd /tmp
    git clone https://github.com/stnava/ANTs.git
    mkdir /opt/ants
    cd /opt/ants
    cmake -c -g /tmp/ANTs
    make -j 4
    ANTSPATH=/opt/ants/bin
    cp /tmp/ANTs/Scripts/antsIntroduction.sh ${ANTSPATH}
    cp /tmp/ANTs/Scripts/antsAtroposN4.sh ${ANTSPATH}
    cp /tmp/ANTs/Scripts/antsBrainExtraction.sh ${ANTSPATH}
    cp /tmp/ANTs/Scripts/antsCorticalThickness.sh ${ANTSPATH}
    echo '# Path to ANTS' >> $CPAC_ENV
    echo 'export ANTSPATH=/opt/ants/bin/' >> $CPAC_ENV
    echo 'export PATH=/opt/ants/bin:$PATH' >> $CPAC_ENV
fi
# --- Install C3D ---
if [ $C3DFLAG -eq 0 ]
then
    echo '---------- INSTALLING C3D... ----------'
    cd /tmp	
    wget http://sourceforge.net/projects/c3d/files/c3d/c3d-0.8.2/${C3D_DOWNLOAD}.tar.gz
    tar xfz ${C3D_DOWNLOAD}.tar.gz
    mv $C3D_DOWNLOAD /opt/c3d
    echo '# Path to C3D' >> $CPAC_ENV
    echo 'export PATH=/opt/c3d/bin:$PATH' >> $CPAC_ENV
fi
##### Copy CPAC image resources #####
echo '########## ACQUIRING CPAC IMAGE RESOURCES... ##########'
cd /vagrant
tar xfz cpac_resources.tar.gz
cd cpac_image_resources
./install_resources.sh $FSLDIR
##### Cleanup and re-source #####
echo '########## CLEANING UP... ##########'
# --- Remove unnexessary files ---
apt-get autoremove -y
rm -r /tmp/nipype
rm -r /tmp/ANTs
rm /tmp/${C3D_DOWNLOAD}.tar.gz
# --- Re-source env vars and exit ---
source /etc/profile.d/cpac_env.sh
echo '########## DONE! ##########'
echo 'TO BEGIN USING CPAC, OPEN A NEW TERMINAL WINDOW AND EXECUTE \"cpac_gui\"'
exit 0
