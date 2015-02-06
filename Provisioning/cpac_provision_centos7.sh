#! /bin/bash
#
# cpac_provision_centos.sh
# A script to provision CentOS 7-based systems.
# This is a work in progress based off cpac_install.sh.
# Potential Feature - allow the script to take in parameters to specify versions
# of ANTs, Nipype, AFNI, c3d.
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
NIPYPEFLAG=`python -c 'import nipype; print nipype.__version__' 2> /dev/null | grep -c 0.10` 
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
##### Acquire yum-supported packages and dependencies #####
echo '########## UPDATING SOFTWARE... ##########'
# --- Ensure software is up-to-date ---
yum update -y
# --- Install other utilities/libraries ---
# Git is needed for version control of source code (ANTs)
# Make is needed to compile source code (cmake, ANTs)
# Unzip is needed to unarchive zip files
# CPAC GUI needs libcanberra-gtk2 module
# AFNI (afni itself) needs: libXp.x86_64, netpbm. AFNI tools (e.g. 3dSkullStrip) need: libGLU-9, gsl
# CMAKE and ANTs require zlib to build latest ANTs from source
echo '---------- ACQUIRING NEEDED UTILITIES/LIBRARIES... ----------'
# For wxPython
cd /tmp && wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm && rpm -Uvh epel-release-7-5.noarch.rpm
yum install -y git make unzip netpbm gcc python-devel gcc-gfortran gcc-c++ libgfortran lapack lapack-devel blas libcanberra-gtk2 libXp.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64 gsl-1.15-13.el7.x86_64 wxBase wxGTK wxGTK-gl wxPython graphviz graphviz-devel.x86_64
#yum install -y cmake zlib-1.2.7-13.el7.x86_64 zlib-devel
# --- Install python packages ---
echo '---------- ACQUIRING PYTHON DEPENDENCIES... ----------'
if [ ! -d /usr/local/bin/miniconda ]
then
    cd /tmp && wget http://repo.continuum.io/miniconda/Miniconda-3.8.3-Linux-x86_64.sh && chmod +x Miniconda-3.8.3-Linux-x86_64.sh && ./Miniconda-3.8.3-Linux-x86_64.sh -b -p /usr/local/bin/miniconda
    # Allow non-root users to install Python packages with the Miniconda installation.
    chmod -R 777 /usr/local/bin/miniconda
    export PATH=/usr/local/bin/miniconda/bin:${PATH}
    export PYTHONPATH=/usr/local/bin/miniconda/envs/cpac/bin
    # Create a Miniconda environment for testing
    yes | conda create -n cpac python
    # Transfer wx and other packages. 
    yes n | mv /usr/lib64/python2.7/site-packages/* /usr/local/bin/miniconda/lib/python2.7/site-packages 
    yes n | mv /usr/lib/python2.7/site-packages/* /usr/local/bin/miniconda/lib/python2.7/site-packages 
    conda install -y cython numpy scipy matplotlib networkx traits pyyaml jinja2 nose ipython pip
    pip install lockfile pygraphviz nibabel
    echo 'export PATH=/usr/local/bin/miniconda/bin:${PATH}' >> $CPAC_ENV
    echo 'export PYTHONPATH=/usr/local/bin/miniconda/envs/cpac/bin' >> $CPAC_ENV
fi
# Problem - matplotlib cannot detect Truetype and libpng, even though they are installed.  This might require
# some symbolic links.
# --- Sun Grid Engine compatibility (uncomment if you want SGE compatibility) ---
#yum install -y motif-2.3.4-7.el7.x86_64 nfs-utils nfs-utils-lib 
#
##### Install needed packages #####
echo '########## INSTALLING SOFTWARE TOOLS... ##########'
#--- Install Nipype 0.10 ---
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
    # Note - this script uses the FSL Installer rather than the Neurodebian repos (used in Ubuntu provisioning script).
    cd /tmp
    wget fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
    echo /usr/share | python fslinstaller.py
    FSLDIR=/usr/share/fsl/
    mkdir $FSLDIR/5.0
    mv $FSLDIR/bin $FSLDIR/5.0/bin
    cp -r $FSLDIR/data $FSLDIR/5.0/data
    mv $FSLDIR/doc $FSLDIR/5.0/doc
    mv $FSLDIR/etc $FSLDIR/5.0/etc
    mv $FSLDIR/tcl $FSLDIR/5.0/tcl
    FSLDIR=$FSLDIR/5.0
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
    wget http://downloads.sourceforge.net/project/advants/ANTS/ANTS_1_9_x/ANTs-1.9.x-Linux.tar.gz
    tar xfz ANTs-1.9.x-Linux.tar.gz
    mv ANTs-1.9.x-Linux /opt/ants
    ANTSPATH=/opt/ants/bin
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
#
##### Copy CPAC image resources #####
echo '########## ACQUIRING CPAC IMAGE RESOURCES... ##########'
cd /vagrant
tar xfz cpac_resources.tar.gz
cd cpac_image_resources
./install_resources.sh $FSLDIR
##### Cleanup and resource #####
echo '########## CLEANING UP... ##########'
# --- Remove unnexessary files ---
yum autoremove -y
if [ $NIPYPEFLAG -eq 0 ];
then
    rm -r /tmp/nipype
fi
if [ $C3DFLAG -eq 0 ];
then
    rm /tmp/${C3D_DOWNLOAD}.tar.gz
fi
source $CPAC_ENV
echo '########## DONE! ##########'
echo 'TO BEGIN USING CPAC, OPEN A NEW TERMINAL WINDOW AND EXECUTE \"cpac_gui\"'
exit 0
