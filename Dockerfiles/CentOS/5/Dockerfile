FROM centos:5
MAINTAINER John Pellman <john.pellman@childmind.org>

# Hook in the install script.
COPY cpac_install.sh /tmp/cpac_install.sh

## Install wget
RUN yum install -y wget

# Install system dependencies
RUN /tmp/cpac_install.sh -s

# Install python dependencies
RUN /tmp/cpac_install.sh -p

# Install FSL
ENV FSLDIR /usr/share/fsl
RUN cd /tmp && \
	wget fsl.fmrib.ox.ac.uk/fsldownloads/fslinstaller.py && \
	python fslinstaller.py -d /usr/share && \
	mkdir $FSLDIR/5.0 && \
	mv $FSLDIR/bin $FSLDIR/5.0/bin && \
	ln -s $FSLDIR/data $FSLDIR/5.0/data && \
	mv $FSLDIR/doc $FSLDIR/5.0/doc && \
	mv $FSLDIR/etc $FSLDIR/5.0/etc && \
	mv $FSLDIR/tcl $FSLDIR/5.0/tcl

# Install C3D
RUN  wget http://sourceforge.net/projects/c3d/files/c3d/c3d-0.8.2/c3d-0.8.2-Linux-x86_64.tar.gz && \
     tar xfz c3d-0.8.2-Linux-x86_64.tar.gz && \
     mv c3d-0.8.2-Linux-x86_64 /opt/c3d && \
     rm c3d-0.8.2-Linux-x86_64.tar.gz

# Set ANTS variables
ENV ANTSPATH /opt/ants/bin/

# Install ANTS
RUN cd /tmp && \
	git clone https://github.com/stnava/ANTs.git && \
	mkdir /opt/ants && \
	cd /opt/ants && \
	cmake -c -g /tmp/ANTs && \
	make && \
	cp /tmp/ANTs/Scripts/antsIntroduction.sh ${ANTSPATH} && \
	cp /tmp/ANTs/Scripts/antsAtroposN4.sh ${ANTSPATH} && \
	cp /tmp/ANTs/Scripts/antsBrainExtraction.sh ${ANTSPATH} && \
	cp /tmp/ANTs/Scripts/antsCorticalThickness.sh ${ANTSPATH}

# Install AFNI
COPY afni_minimal.tar.gz /tmp/
RUN tar xfz /tmp/afni_minimal.tar.gz && \
    mv afni_minimal /opt/afni && \
    rm /tmp/afni_minimal.tar.gz && \

# Install CPAC templates
COPY cpac_templates.tar.gz /tmp/cpac_templates.tar.gz
RUN cd /tmp && \
    tar xfz cpac_resources.tar.gz && \
    cd cpac_image_resources && \
    cp -n MNI_3mm/* $FSLDIR/data/standard && \
    cp -n MNI_4mm/* $FSLDIR/data/standard && \
    cp -n symmetric/* $FSLDIR/data/standard && \
    cp -nr tissuepriors/2mm $FSLDIR/data/standard/tissuepriors && \
    cp -nr tissuepriors/3mm $FSLDIR/data/standard/tissuepriors && \
    cp -nr tissuepriors/4mm $FSLDIR/data/standard/tissuepriors && \
    cp -n HarvardOxford-lateral-ventricles-thr25-2mm.nii.gz $FSLDIR/data/atlases/HarvardOxford && \
    cd /tmp && \
    rm -r cpac_image_resources && \
    rm cpac_resources.tar.gz

# Set FSL variables
ENV FSLDIR /usr/share/fsl/5.0
ENV FSLOUTPUTTYPE NIFTI_GZ
ENV FSLMULTIFILEQUIT TRUE
ENV FSLTCLSH /usr/bin/tclsh
ENV FSLWISH /usr/bin/wish
ENV FSLBROWSER /etc/alternatives/x-www-browser

# Set AFNI variables
ENV DYLD_FALLBACK_LIBRARY_PATH /opt/afni
ENV LD_LIBRARY_PATH /usr/lib/fsl/5.0:${LD_LIBRARY_PATH}

# Set overall path
ENV PATH /code:/opt/c3d/bin:/opt/ants/bin:/opt/afni:${FSLDIR}/bin:/usr/local/bin/miniconda/bin:${PATH}

# Install CPAC from the development branch.
COPY cpac_branch_install.sh /tmp/cpac_branch_install.sh
RUN /tmp/cpac_branch_install.sh

# Copy in pipeline config and participant list.
COPY test_pipeline.yaml /tmp/test_pipeline.yaml
COPY test_participants.yaml /tmp/test_participants.yaml

ENTRYPOINT ["/usr/local/bin/miniconda/envs/cpac/bin/cpac_run.py","/tmp/test_pipeline.yaml","/tmp/test_participants.yaml"]
