#! /bin/bash

# A function to install system dependencies.
# Arguments: islocal, distro
function install_system_dependencies {
	if [ $# -ne 2 ]; then
		echo install_system_dependencies requires two arguments - islocal, distro
		echo Received $#
		exit 1
	fi
	if [ $1 -eq 0 ]; then
		if [ $2 == 'CENTOS']; then
			yum update -y
			cd /tmp && wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm && rpm -Uvh epel-release-7-5.noarch.rpm
			yum install -y git make unzip netpbm gcc python-devel gcc-gfortran gcc-c++ libgfortran lapack lapack-devel blas libcanberra-gtk2 libXp.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64 gsl-1.15-13.el7.x86_64 wxBase wxGTK wxGTK-gl wxPython graphviz graphviz-devel.x86_64
			yum autoremove -y
		elif [ $2 == 'UBUNTU' ]; then
			apt-get update
			apt-get upgrade -y
			apt-get install -y cmake git make unzip libcanberra-gtk-module libxp6 netpbm libglu1 gsl-bin zlib1g-dev
			apt-get autoremove -y
		else
			echo Linux distribution not recognized.  System-level dependencies cannot be installed.
			exit 1
		fi	
	elif [ $1 -eq 1]; then
		echo System-level dependencies cannot be installed since you do not have root privileges.
		echo Re-run this script as root or have your system administrator run it.
		exit 1
	else
		echo Invalid value for variable 'LOCAL'.
		echo This script is unable to determine whether or not you are running it as root.
		exit 1
	fi
}

# A function to install Python dependencies via Miniconda.
function install_python_dependencies {
	if [ $# -ne 1 ]; then
		echo install_python_dependencies requires 1 argument - islocal
		echo Received $#
		exit 1
	fi
	current=$(pwd)
	cd /tmp 
	wget http://repo.continuum.io/miniconda/Miniconda-3.8.3-Linux-x86_64.sh 
	chmod +x Miniconda-3.8.3-Linux-x86_64.sh
	if [ $1 -eq 0 ]; then
		./Miniconda-3.8.3-Linux-x86_64.sh -b -p /usr/local/bin/miniconda
		chmod -R 777 /usr/local/bin/miniconda
		export PATH=/usr/local/bin/miniconda/bin:${PATH}
		echo 'export PATH=/usr/local/bin/miniconda/bin:${PATH}' >> ~/cpac_env.sh
	elif [ $1 -eq 1 ] && [ ! -d ~/miniconda ]; then
		./Miniconda-3.8.3-Linux-x86_64.sh -b
		export PATH=~/miniconda/bin:${PATH}
		echo 'export PATH=~/miniconda/bin:${PATH}' >> ~/cpac_env.sh
	fi
	rm /tmp/Miniconda-3.8.3-Linux-x86_64.sh
	if [ ! -d ~/miniconda/envs/cpac ]; then
		conda create -y -n cpac python
		source activate cpac
		conda install -y cython numpy scipy matplotlib networkx traits pyyaml jinja2 nose ipython pip
 		pip install lockfile pygraphviz nibabel nipype
		source deactivate
	fi
	cd $current
	
}

# A function to install FSL.
# Arguments: islocal, distro
function install_fsl {
	if [ $# -ne 2 ]; then
		echo install_fsl requires 2 arguments - islocal, distro
		echo Received $#
		exit 1
	fi
	current=$(pwd)
    	cd /tmp
	wget fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
	if [ $1 -eq 0 ]; then
		if [ $2 == 'CENTOS' ]; then
			python fslinstaller.py -d /usr/share
			FSLDIR=/usr/share/fsl/
			mkdir $FSLDIR/5.0
			mv $FSLDIR/bin $FSLDIR/5.0/bin
			cp -r $FSLDIR/data $FSLDIR/5.0/data
			mv $FSLDIR/doc $FSLDIR/5.0/doc
			mv $FSLDIR/etc $FSLDIR/5.0/etc
			mv $FSLDIR/tcl $FSLDIR/5.0/tcl
		# Debian-based distros must use NeuroDebian instead of the installer.
		elif [ $2 == 'UBUNTU' ]; then
			wget -O- http://neuro.debian.net/lists/$(lsb_release -cs).us-nh.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
			apt-key adv --recv-keys --keyserver pgp.mit.edu 2649A5A9
			apt-get update
			apt-get install -y fsl-5.0-complete
		fi
		echo '# Path to FSL' >> ~/cpac_env.sh
		echo 'FSLDIR=/usr/share/fsl/5.0' >> ~/cpac_env.sh
		echo '. ${FSLDIR}/etc/fslconf/fsl.sh' >> ~/cpac_env.sh
		echo 'PATH=${FSLDIR}/bin:${PATH}' >> ~/cpac_env.sh
		echo 'export FSLDIR PATH' >> ~/cpac_env.sh
		rm fslinstaller.py
	elif [ $1 -eq 1]; then
		if [ $2 == 'CENTOS' ]; then
                        python fslinstaller.py -d ~ 
                        FSLDIR=~/fsl/
                        mkdir $FSLDIR/5.0
                        mv $FSLDIR/bin $FSLDIR/5.0/bin
                        cp -r $FSLDIR/data $FSLDIR/5.0/data
                        mv $FSLDIR/doc $FSLDIR/5.0/doc
                        mv $FSLDIR/etc $FSLDIR/5.0/etc
                        mv $FSLDIR/tcl $FSLDIR/5.0/tcl
			echo '# Path to FSL' >> ~/cpac_env.sh
                	echo 'FSLDIR=~/fsl/5.0' >> ~/cpac_env.sh
                	echo '. ${FSLDIR}/etc/fslconf/fsl.sh' >> ~/cpac_env.sh
                	echo 'PATH=${FSLDIR}/bin:${PATH}' >> ~/cpac_env.sh
                	echo 'export FSLDIR PATH' >> ~/cpac_env.sh			
		elif [ $2 == 'UBUNTU']; then
			echo FSL cannot be installed without root privileges on Ubuntu Linux.
			cd $current
			exit 1
		fi
	else
		echo Invalid value for variable 'LOCAL'.
		echo This script is unable to determine whether or not you are running it as root.
		cd $current
		exit 1
	fi
	cd $current
	
}

# A function to install AFNI.
# Arguments: islocal 
function install_afni {
	if [ $# -ne 1 ]; then
		echo install_afni requires 1 argument - islocal
		echo Received $#
		exit 1
	fi
	current=$(pwd)
	cd /tmp
	if [ $(uname -p) == 'x86_64']; then
		AFNI_DOWNLOAD=linux_openmp_64
	else
		AFNI_DOWNLOAD=linux_openmp
	fi
    	wget --no-check-certificate https://afni.nimh.nih.gov/pub/dist/tgz/${AFNI_DOWNLOAD}.tgz
    	tar xfz ${AFNI_DOWNLOAD}.tgz
	if [ $1 -eq 0 ]; then
    		mv ${AFNI_DOWNLOAD} /opt/afni
    		echo '# Path to AFNI' >> ~/cpac_env.sh
    		echo 'export PATH=/opt/afni:$PATH' >> ~/cpac_env.sh
    		echo 'export DYLD_FALLBACK_LIBRARY_PATH=/opt/afni' >> ~/cpac_env.sh

	elif [ $1 -eq 1]; then
    		mv ${AFNI_DOWNLOAD} ~/afni 
    		echo '# Path to AFNI' >> ~/cpac_env.sh
    		echo 'export PATH=~/afni:$PATH' >> ~/cpac_env.sh
    		echo 'export DYLD_FALLBACK_LIBRARY_PATH=~/afni' >> ~/cpac_env.sh
	else
		echo Invalid value for variable 'LOCAL'.
		echo This script is unable to determine whether or not you are running it as root.
		cd $current
		exit 1
	fi
	cd $current
	
}

# A function to install ANTS.
# Arguments: islocal
function install_ants {
	if [ $# -ne 1 ]; then
		echo install_ants requires 1 argument - islocal
		echo Received $#
		exit 1
	fi
	current=$(pwd)
    	cd /tmp
    	git clone https://github.com/stnava/ANTs.git
	if [ $1 -eq 0 ]; then
		mkdir /opt/ants
		cd /opt/ants
		cmake -c -g /tmp/ANTs
		make -j 4
		ANTSPATH=/opt/ants/bin
		cp /tmp/ANTs/Scripts/antsIntroduction.sh ${ANTSPATH}
		cp /tmp/ANTs/Scripts/antsAtroposN4.sh ${ANTSPATH}
		cp /tmp/ANTs/Scripts/antsBrainExtraction.sh ${ANTSPATH}
		cp /tmp/ANTs/Scripts/antsCorticalThickness.sh ${ANTSPATH}
		echo '# Path to ANTS' >> ~/cpac_env.sh
		echo 'export ANTSPATH=/opt/ants/bin/' >> ~/cpac_env.sh
		echo 'export PATH=/opt/ants/bin:$PATH' >> ~/cpac_env.sh
	elif [ $1 -eq 1]; then
		mkdir ~/ants
		cd ~/ants
		cmake -c -g /tmp/ANTs
		make -j 4
		ANTSPATH=~/ants/bin
		cp /tmp/ANTs/Scripts/antsIntroduction.sh ${ANTSPATH}
		cp /tmp/ANTs/Scripts/antsAtroposN4.sh ${ANTSPATH}
		cp /tmp/ANTs/Scripts/antsBrainExtraction.sh ${ANTSPATH}
		cp /tmp/ANTs/Scripts/antsCorticalThickness.sh ${ANTSPATH}
		echo '# Path to ANTS' >> ~/cpac_env.sh
		echo 'export ANTSPATH=~/ants/bin/' >> ~/cpac_env.sh
		echo 'export PATH=~/ants/bin:$PATH' >> ~/cpac_env.sh
	else
		echo Invalid value for variable 'LOCAL'.
		echo This script is unable to determine whether or not you are running it as root.
		cd $current
		exit 1
	fi
	cd $current
	
}


# A function to install C3D.
# Arguments: islocal
function install_c3d {
	if [ $# -ne 1 ]; then
		echo install_c3d requires 1 argument - islocal
		echo Received $#
		exit 1
	fi
	current=$(pwd)
	ARCHITECTURE=$(uname -p)
	case $ARCHITECTURE in
    		x86_64 )
        		C3D_DOWNLOAD=c3d-0.8.2-Linux-x86_64
        		;;
    		i386 )
        		C3D_DOWNLOAD=c3d-0.8.2-Linux-i386
        		;;
   		i686 )
        		C3D_DOWNLOAD=c3d-0.8.2-Linux-i686
     			;;
	esac
	cd /tmp
	wget http://sourceforge.net/projects/c3d/files/c3d/c3d-0.8.2/${C3D_DOWNLOAD}.tar.gz
	tar xfz ${C3D_DOWNLOAD}.tar.gz
	if [ $1 -eq 0 ]; then
		mv $C3D_DOWNLOAD /opt/c3d
		echo '# Path to C3D' >> ~/cpac_env.sh
		echo 'export PATH=/opt/c3d/bin:$PATH' >> ~/cpac_env.sh
	elif [ $1 -eq 1]; then
		mv $C3D_DOWNLOAD ~/c3d
		echo '# Path to C3D' >> ~/cpac_env.sh
		echo 'export PATH=~/c3d/bin:$PATH' >> ~/cpac_env.sh
	else
		echo Invalid value for variable 'LOCAL'.
		echo This script is unable to determine whether or not you are running it as root.
		cd $current
		exit 1
	fi
	cd $current
	
}

# A function to install C-PAC image resources (e.g., symmetric templates).
# Arguments: islocal
function install_cpac_templates {
	if [ $# -ne 1 ]; then
		echo install_cpac_templates requires 1 argument - islocal
		echo Received $#
		exit 1
	fi
	current=$(pwd)
	cd /tmp
	wget http://fcon_1000.projects.nitrc.org/indi/cpac_resources.tgz
	tar xfz cpac_resources.tgz
	cd cpac_image_resources
	cp MNI_3mm/* $FSLDIR/data/standard
	cp symmetric/* $FSLDIR/data/standard
	cp -r tissuepriors/2mm $FSLDIR/data/standard/tissuepriors
	cp -r tissuepriors/3mm $FSLDIR/data/standard/tissuepriors
	cp HarvardOxford-lateral-ventricles-thr25-2mm.nii.gz $FSLDIR/data/atlases/HarvardOxford
	cd $current
}

# A function to install C-PAC image resources (e.g., symmetric templates).
# Arguments: islocal
function install_cpac {
	current=$(pwd)
	source activate cpac
	cd /tmp
	git clone https://github.com/FCP-INDI/C-PAC.git
	cd C-PAC
	python setup.py install
	source deactivate
	cd $current
	rm -r /tmp/C-PAC
}

# Check to see if user has root privileges.  If not, perform local install.
[ $EUID -eq 0 ] && LOCAL=0 || LOCAL=1

# Check to see whether the distribution is CentOS or Ubuntu.
[ -f /etc/redhat-release ] && DISTRO=CENTOS
[ $(lsb_release -si) == 'Ubuntu' ] && DISTRO=UBUNTU

# Check for pre-existing software.
which flirt && FSLFLAG=1 || FSLFLAG=0
which afni && AFNIFLAG=1 || AFNIFLAG=0
which ANTS && ANTSFLAG=1 || ANTSFLAG=0
which c3d && C3DFLAG=1 || C3DFLAG=0

install_system_dependencies $LOCAL $DISTRO
install_python_dependencies $LOCAL
install_fsl $LOCAL $DISTRO
install_afni $LOCAL
install_ants $LOCAL
install_c3d $LOCAL
install_cpac_templates $LOCAL
install_cpac 

# Append cpac_env.sh to end of bashrc and remove if this is not root.  Otherwise move cpac_env.sh to /etc/profile.d
if [ $LOCAL -eq 1 ]; then
	cat ~/cpac_env.sh >> ~/.bashrc
	rm ~/cpac.env.sh
elif [ $LOCAL -eq 0 ]; then
	if [ -f /etc/profile.d/cpac_env.sh ]; then
		echo Previous copy of CPAC environmental variables file found in /etc/profile.d
		echo Check for compatibility issues with the version created in /root/cpac_env.sh
		echo and then merge if necessary.
	else
		mv ~/cpac_env.sh /etc/profile.d/
	fi
fi
