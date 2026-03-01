FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    software-properties-common \
    dirmngr \
    gnupg \
    wget \
    curl \
    git \
    autoconf \
    automake \
    libtool \
    libbz2-dev \
    liblzma-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libjpeg-dev \
    libtiff5-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    zlib1g-dev \
    pkg-config \
    openjdk-21-jre-headless \
    python3-pip \
    libxml2-dev libssl-dev libcurl4-openssl-dev \
    ca-certificates \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 \
    && add-apt-repository 'deb https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/' \
    && apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    r-base-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tools

# meryl
RUN wget https://github.com/marbl/meryl/releases/download/v1.4.1/meryl-1.4.1.Linux-amd64.tar.xz && \
    tar -xJf meryl-1.4.1.Linux-amd64.tar.xz
ENV PATH=/tools/meryl-1.4.1/bin:$PATH

# merqury
RUN git clone https://github.com/marbl/merqury.git \
    && cd merqury \
    && git checkout 1ad7c32 \
    && rm -rf .git 
ENV MERQURY=/tools/merqury

# samtools
RUN wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2 && \
    tar jxvf samtools-1.17.tar.bz2 && \
    cd samtools-1.17/htslib-1.17 && ./configure && make && make install && \
    cd ../ && ./configure --without-curses && make && make install

# bedtools
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.31.1/bedtools-2.31.1.tar.gz && \
    tar xvzf bedtools-2.31.1.tar.gz && \
    cd bedtools2 && make
ENV PATH=/tools/bedtools2/bin:$PATH

# R packages
RUN R -e "install.packages(c('argparse','tidyverse'), repos='https://cloud.r-project.org/')"

RUN pip3 install argparse

CMD ["/bin/bash"]
