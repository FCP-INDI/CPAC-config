FROM ubuntu:12.04
MAINTAINER John Pellman <john.pellman@childmind.org>

# Hook in the install script.
COPY cpac_install.sh /tmp/cpac_install.sh

## Install wget
RUN apt-get update && apt-get install -y wget

# Install system dependencies
RUN apt-get update && /tmp/cpac_install.sh -s

# Install python dependencies
RUN /tmp/cpac_install.sh -p

# Install Neurodebian Keys
RUN wget -O- http://neuro.debian.net/lists/precise.au.full | tee /etc/apt/sources.list.d/neurodebian.sources.list && \
            apt-key adv --recv-keys --keyserver hkp://pgp.mit.edu:80 0xA5D32F012649A5A9 && \
            apt-get update 

# Install FSL
RUN apt-get install -y fsl-5.0-core 

# Install C3D
RUN  wget http://sourceforge.net/projects/c3d/files/c3d/c3d-0.8.2/c3d-0.8.2-Linux-x86_64.tar.gz && \
     tar xfz c3d-0.8.2-Linux-x86_64.tar.gz && \
     mv c3d-0.8.2-Linux-x86_64 /opt/c3d && \
     rm c3d-0.8.2-Linux-x86_64.tar.gz

# Install ANTS
RUN apt-get update && \
    apt-get install -y ants

# Install AFNI
COPY afni_minimal.tar.gz /tmp/
RUN tar xfz /tmp/afni_minimal.tar.gz && \
    mv afni_minimal /opt/afni && \
    rm /tmp/afni_minimal.tar.gz && \

# Install CPAC templates
COPY cpac_templates.tar.gz /tmp/cpac_templates.tar.gz
RUN cd /tmp
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

# Set ANTS variables
ENV ANTSPATH /opt/ants/bin/

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
