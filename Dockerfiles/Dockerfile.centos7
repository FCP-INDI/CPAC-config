FROM centos:7
MAINTAINER John Pellman
# Use Bash
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# Install system-wide dependencies
RUN yum update -y && yum install -y wget && cd /tmp && wget http://dl.fedoraproject.org/pub/epel/7/x86_64/e/epel-release-7-5.noarch.rpm && rpm -Uvh epel-release-7-5.noarch.rpm && yum install -y cmake git make unzip netpbm gcc python-devel gcc-gfortran gcc-c++ libgfortran lapack lapack-devel blas libcanberra-gtk2 libXp.x86_64 mesa-libGLU-9.0.0-4.el7.x86_64 gsl-1.15-13.el7.x86_64 wxBase wxGTK wxGTK-gl wxPython graphviz graphviz-devel.x86_64 zlib-devel tar bzip2 libpng12 && yum autoremove -y

# Install Python dependencies
RUN cd /tmp && wget http://repo.continuum.io/miniconda/Miniconda-3.8.3-Linux-x86_64.sh && chmod +x Miniconda-3.8.3-Linux-x86_64.sh && ./Miniconda-3.8.3-Linux-x86_64.sh -b -p /usr/local/bin/miniconda && chmod -R 775 /usr/local/bin/miniconda && chmod g+s /usr/local/bin/miniconda
ENV PATH /usr/local/bin/miniconda/bin:$PATH
RUN conda create -y -n cpac python && source activate cpac && conda install -y cython numpy scipy matplotlib networkx traits pyyaml jinja2 nose ipython pip wxpython && pip install lockfile pygraphviz nibabel nipype patsy && source deactivate

# Download the FSL installer, install FSL, and set FSL environment variables.
ENV SHELL /bin/bash
RUN cd /tmp && wget fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && python fslinstaller.py -d /usr/share && mkdir /usr/share/fsl/5.0 && mv /usr/share/fsl/bin /usr/share/fsl/5.0/bin && ln -s /usr/share/fsl/data /usr/share/fsl/5.0/data && mv /usr/share/fsl/doc /usr/share/fsl/5.0/doc && mv /usr/share/fsl/etc /usr/share/fsl/5.0/etc && mv /usr/share/fsl/tcl /usr/share/fsl/5.0/tcl 
ENV FSLDIR /usr/share/fsl/5.0  
ENV FSLOUTPUTTYPE NIFTI_GZ 
ENV FSLMULTIFILEQUIT TRUE
ENV FSLTCLSH /usr/bin/tclsh
ENV FSLWISH /usr/bin/wish
ENV FSLBROWSER /etc/alternatives/x-www-browser
ENV POSSUMDIR $FSLDIR 
ENV PATH $PATH:/usr/share/fsl/5.0/bin
ENV LD_LIBRARY_PATH /usr/lib/fsl/5.0

# Install AFNI and set environment variables
RUN cd /tmp && wget --no-check-certificate https://afni.nimh.nih.gov/pub/dist/tgz/linux_openmp_64.tgz && tar xfz /tmp/linux_openmp_64.tgz && mv /tmp/linux_openmp_64 /opt/afni
ENV PATH /opt/afni:$PATH
ENV DYLD_FALLBACK_LIBRARY_PATH /opt/afni

# Install C3D
RUN cd /tmp && wget http://sourceforge.net/projects/c3d/files/c3d/c3d-0.8.2/c3d-0.8.2-Linux-x86_64.tar.gz && tar xfz /tmp/c3d-0.8.2-Linux-x86_64.tar.gz && mv /tmp/c3d-0.8.2-Linux-x86_64 /opt/c3d
ENV PATH /opt/c3d/bin:$PATH

# Install ANTs
RUN cd /tmp && git clone https://github.com/stnava/ANTs.git && mkdir /opt/ants && cd /opt/ants && cmake -c -g /tmp/ANTs  && make -j 4 && mv /tmp/ANTs/Scripts/antsIntroduction.sh /opt/ants/bin && mv /tmp/ANTs/Scripts/antsAtroposN4.sh /opt/ants/bin && mv /tmp/ANTs/Scripts/antsBrainExtraction.sh /opt/ants/bin && mv /tmp/ANTs/Scripts/antsCorticalThickness.sh /opt/ants/bin
ENV ANTSPATH /opt/ants/bin
ENV PATH /opt/ants/bin:$PATH

# Install C-PAC Resources
RUN cd /tmp && wget http://fcon_1000.projects.nitrc.org/indi/cpac_resources.tgz && tar xfz cpac_resources.tgz && cd cpac_image_resources && cp -n MNI_3mm/* $FSLDIR/data/standard && cp -n symmetric/* $FSLDIR/data/standard && cp -nr tissuepriors/2mm $FSLDIR/data/standard/tissuepriors && cp -nr tissuepriors/3mm $FSLDIR/data/standard/tissuepriors && cp -n HarvardOxford-lateral-ventricles-thr25-2mm.nii.gz $FSLDIR/data/atlases/HarvardOxford
