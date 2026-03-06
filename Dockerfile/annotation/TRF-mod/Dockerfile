FROM centos:7
LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-* && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-* && \
    yum -y update && \
    yum -y install wget git bgzip2 gcc gcc-c++ make && \
    yum clean all

WORKDIR /opt
RUN git clone https://github.com/lh3/TRF-mod && \
  cd TRF-mod && \
  git checkout 3e891db && \
  make -f compile.mak

ENV PATH=/opt/TRF-mod:${PATH}

