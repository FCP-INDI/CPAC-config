FROM ubuntu:12.04
MAINTAINER John Pellman <john.pellman@childmind.org>

# Specify C-PAC branch to pull from and location of common local resources.
ARG branch=master
ARG respath=/tdata/Configs/Dockerfiles/Common_Resources

## Install wget and git
RUN apt-get update && apt-get install -y wget git

# Clone CPAC from the development branch.
RUN cd /tmp && git clone -b ${branch} https://github.com/FCP-INDI/C-PAC.git

# Install system dependencies
RUN /tmp/C-PAC/scripts/cpac_install.sh -s

# Install python dependencies
RUN /tmp/C-PAC/scripts/cpac_install.sh -p

# Install Neuroimaging suites
RUN /tmp/C-PAC/scripts/cpac_install.sh -n "fsl c3d ants cpac_resources"

# Install AFNI
COPY ${respath}/afni_minimal.tar.gz /tmp/
RUN tar xfz /tmp/afni_minimal.tar.gz && \
    mv afni_minimal /opt/afni && \
    rm /tmp/afni_minimal.tar.gz

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

# Copy in pipeline config and participant list.
COPY test_pipeline.yaml /tmp/test_pipeline.yaml
COPY test_participants.yaml /tmp/test_participants.yaml

ENTRYPOINT ["/usr/local/bin/miniconda/envs/cpac/bin/cpac_run.py","/tmp/test_pipeline.yaml","/tmp/test_participants.yaml"]
