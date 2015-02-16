#! /bin/bash

# Flags:
# -s : System-level dependencies only.
# -p : Python dependencies only
# --afni : AFNI only. 
# --fsl : FSL only. 
# --ants : ANTS only. 
# --c3d : C3D only.
# --cpac : CPAC only.
# -n : Install all neuroimaging suites not already installed.  Will also tell you if all neuroimaging suites are already installed and on the path.
# -l : Local install. Equivalent to -p -n ; will not run FSL installer, but will issue a warning if running on Ubuntu. 
# -r : Root install.  Equivalent to -s -p -n

# A function to install system dependencies.
function install_system_dependencies {
	if [ $LOCAL -eq 0 ]; then
		if [ $DISTRO == 'CENTOS']; then
			yum update -y
			cd /tmp && wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm && rpm -Uvh epel-release-7-5.noarch.rpm
			yum install -y git make unzip netpbm gcc python-devel gcc-gfortran gcc-c++ libgfortran lapack lapack-devel blas libcanberra-gtk2 libXp.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64 gsl-1.15-13.el7.x86_64 wxBase wxGTK wxGTK-gl wxPython graphviz graphviz-devel.x86_64
			yum autoremove -y
		elif [ $DISTRO == 'UBUNTU' ]; then
			apt-get update
			apt-get upgrade -y
			apt-get install -y cmake git make unzip libcanberra-gtk-module libxp6 netpbm libglu1-mesa gsl-bin zlib1g-dev
			apt-get autoremove -y
		else
			echo Linux distribution not recognized.  System-level dependencies cannot be installed.
			exit 1
		fi	
	elif [ $LOCAL -eq 1]; then
		echo System-level dependencies cannot be installed since you do not have root privileges.
		echo Re-run this script as root or have your system administrator run it.
		exit 1
	else
		echo Invalid value for variable 'LOCAL'.
		echo This script is unable to determine whether or not you are running it as root.
		exit 1
	fi
}

# A function to determine whether or not system dependencies are already installed.
function system_dependencies_installed {
	if [ $DISTRO == 'CENTOS' ]; then
		yum list installed git make unzip netpbm gcc python-devel gcc-gfortran gcc-c++ libgfortran lapack lapack-devel blas libcanberra-gtk2 libXp.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64 gsl-1.15-13.el7.x86_64 wxBase wxGTK wxGTK-gl wxPython graphviz graphviz-devel.x86_64 > /dev/null 2>&1
	elif [ $DISTRO == 'UBUNTU' ]; then
		dpkg -s cmake git make unzip libcanberra-gtk-module libxp6 netpbm libglu1-mesa gsl-bin zlib1g-dev > /dev/null 2>&1
	fi
	return $?
}

# A function to install Python dependencies via Miniconda.
function install_python_dependencies {
	system_dependencies_installed ; if [ $? -ne 0 ]; then
		echo Python dependencies cannot be installed unless system-level dependencies are installed first.
		echo Have your system administrator install system-level dependencies as root.
		echo Exiting now...
		exit 1
	fi
	cd /tmp 
	wget http://repo.continuum.io/miniconda/Miniconda-3.8.3-Linux-x86_64.sh 
	chmod +x Miniconda-3.8.3-Linux-x86_64.sh
	if [ $LOCAL -eq 0 ]; then
		./Miniconda-3.8.3-Linux-x86_64.sh -b -p /usr/local/bin/miniconda
		chmod -R 777 /usr/local/bin/miniconda
		export PATH=/usr/local/bin/miniconda/bin:${PATH}
		echo 'export PATH=/usr/local/bin/miniconda/bin:${PATH}' >> ~/cpac_env.sh
	elif [ $LOCAL -eq 1 ] && [ ! -d ~/miniconda ]; then
		./Miniconda-3.8.3-Linux-x86_64.sh -b
		export PATH=~/miniconda/bin:${PATH}
		echo 'export PATH=~/miniconda/bin:${PATH}' >> ~/cpac_env.sh
	fi
	rm /tmp/Miniconda-3.8.3-Linux-x86_64.sh
	if [ ! -d ~/miniconda/envs/cpac ] || [ ! -d /usr/local/bin/miniconda ]; then
		conda create -y -n cpac python
		source activate cpac
		conda install -y cython numpy scipy matplotlib networkx traits pyyaml jinja2 nose ipython pip
 		pip install lockfile pygraphviz nibabel nipype
		source deactivate
	fi
}

# A function to determine whether or not Python dependencies are already installed.
function python_dependencies_installed {
	python -c "import cython, numpy, scipy, matplotlib, networkx, traits, yaml, jinja2, nose, pip, lockfile, pygraphviz, nibabel, nipype" 2> /dev/null && which ipython > /dev/null
	return $?
}

# A function to install FSL.
function install_fsl {
	system_dependencies_installed ; if [ $? -ne 0 ]; then
		echo FSL cannot be installed unless system-level dependencies are installed first.
		echo Have your system administrator install system-level dependencies as root.
		echo Exiting now...
		exit 1
	fi
    	cd /tmp
	wget fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py
	if [ $LOCAL -eq 0 ]; then
		if [ $DISTRO == 'CENTOS' ]; then
			python fslinstaller.py -d /usr/share
			FSLDIR=/usr/share/fsl/
			mkdir $FSLDIR/5.0
			mv $FSLDIR/bin $FSLDIR/5.0/bin
			cp -r $FSLDIR/data $FSLDIR/5.0/data
			mv $FSLDIR/doc $FSLDIR/5.0/doc
			mv $FSLDIR/etc $FSLDIR/5.0/etc
			mv $FSLDIR/tcl $FSLDIR/5.0/tcl
		# Debian-based distros must use NeuroDebian instead of the installer.
		elif [ $DISTRO == 'UBUNTU' ]; then
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
	elif [ $LOCAL -eq 1]; then
		if [ $DISTRO == 'CENTOS' ]; then
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
		elif [ $DISTRO == 'UBUNTU']; then
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
}

# A function to install AFNI.
function install_afni {
	system_dependencies_installed ; if [ $? -ne 0 ]; then
		echo AFNI cannot be installed unless system-level dependencies are installed first.
		echo Have your system administrator install system-level dependencies as root.
		echo Exiting now...
		exit 1
	fi
	cd /tmp
	if [ $(uname -p) == 'x86_64']; then
		AFNI_DOWNLOAD=linux_openmp_64
	else
		AFNI_DOWNLOAD=linux_openmp
	fi
    	wget --no-check-certificate https://afni.nimh.nih.gov/pub/dist/tgz/${AFNI_DOWNLOAD}.tgz
    	tar xfz ${AFNI_DOWNLOAD}.tgz
	if [ $LOCAL -eq 0 ]; then
    		mv ${AFNI_DOWNLOAD} /opt/afni
    		echo '# Path to AFNI' >> ~/cpac_env.sh
    		echo 'export PATH=/opt/afni:$PATH' >> ~/cpac_env.sh
    		echo 'export DYLD_FALLBACK_LIBRARY_PATH=/opt/afni' >> ~/cpac_env.sh

	elif [ $LOCAL -eq 1]; then
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
}

# A function to install ANTS.
function install_ants {
	system_dependencies_installed ; if [ $? -ne 0 ]; then
		echo ANTS cannot be installed unless system-level dependencies are installed first.
		echo Have your system administrator install system-level dependencies as root.
		echo Exiting now...
		exit 1
	fi
	which c3d ; if [ $? -ne 0 ]; then
		echo CPAC cannot be installed unless c3d is installed first.
		echo Install AFNI and then try again.
		echo Exiting now...
		exit 1
	fi
    	cd /tmp
    	git clone https://github.com/stnava/ANTs.git
	if [ $LOCAL -eq 0 ]; then
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
	elif [ $LOCAL -eq 1]; then
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
}

# A function to install C3D.
function install_c3d {
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
	if [ $LOCAL -eq 0 ]; then
		mv $C3D_DOWNLOAD /opt/c3d
		echo '# Path to C3D' >> ~/cpac_env.sh
		echo 'export PATH=/opt/c3d/bin:$PATH' >> ~/cpac_env.sh
	elif [ $LOCAL -eq 1]; then
		mv $C3D_DOWNLOAD ~/c3d
		echo '# Path to C3D' >> ~/cpac_env.sh
		echo 'export PATH=~/c3d/bin:$PATH' >> ~/cpac_env.sh
	else
		echo Invalid value for variable 'LOCAL'.
		echo This script is unable to determine whether or not you are running it as root.
		cd $current
		exit 1
	fi
}

# A function to install C-PAC image resources (e.g., symmetric templates).
function install_cpac_templates {
	which fsl ; if [ $? -ne 0 ]; then
		echo CPAC templates cannot be copied unless FSL is installed first.
		echo Install FSL and then try again.
		echo Exiting now...
		exit 1
	fi
	cd /tmp
	wget http://fcon_1000.projects.nitrc.org/indi/cpac_resources.tgz
	tar xfz cpac_resources.tgz
	cd cpac_image_resources
	cp MNI_3mm/* $FSLDIR/data/standard
	cp symmetric/* $FSLDIR/data/standard
	cp -r tissuepriors/2mm $FSLDIR/data/standard/tissuepriors
	cp -r tissuepriors/3mm $FSLDIR/data/standard/tissuepriors
	cp HarvardOxford-lateral-ventricles-thr25-2mm.nii.gz $FSLDIR/data/atlases/HarvardOxford
}

# A function to install C-PAC image resources (e.g., symmetric templates).
# Arguments: islocal
function install_cpac {
	which fsl ; if [ $? -ne 0 ]; then
		echo CPAC cannot be installed unless FSL is installed first.
		echo Install FSL and then try again.
		echo Exiting now...
		exit 1
	fi
	which afni ; if [ $? -ne 0 ]; then
		echo CPAC cannot be installed unless AFNI is installed first.
		echo Install AFNI and then try again.
		echo Exiting now...
		exit 1
	fi
	python_dependencies_installed ; if [ $? -ne 0 ]; then
		echo CPAC cannot be installed unless Python dependencies are installed first.
		echo Install Python dependencies and then try again.
		echo Exiting now...
		exit 1
	fi
	source activate cpac
	cd /tmp
	git clone https://github.com/FCP-INDI/C-PAC.git
	cd C-PAC
	python setup.py install
	source deactivate
	rm -r /tmp/C-PAC
}

# Check to see if user has root privileges.  If not, perform local install.
[ $EUID -eq 0 ] && LOCAL=0 || LOCAL=1

# Check to see whether the distribution is CentOS or Ubuntu.
[ -f /etc/redhat-release ] && DISTRO=CENTOS
[ $(lsb_release -si) == 'Ubuntu' ] && DISTRO=UBUNTU

INIT_DIR=$(pwd)
# TODO: Implement flags here.  Below is placeholder code.
: ${LOCAL:? "LOCAL needs to be set and non-empty."}
: ${DISTRO:? "DISTRO needs to be set and non-empty."}
install_system_dependencies 
install_python_dependencies
install_fsl 
install_afni
install_ants
install_c3d
install_cpac_templates
install_cpac 
cd $INIT_DIR

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
