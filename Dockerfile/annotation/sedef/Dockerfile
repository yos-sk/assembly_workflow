# Sedef - Segmental Duplication Detection

FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"
LABEL description="Sedef segmental duplication detector"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    time \
    bc \
    git \
    wget \
    bzip2 \
    build-essential \
    libboost-all-dev \
    parallel \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tools

# SEDEF
RUN git clone https://github.com/vpc-ccg/sedef && \
    cd sedef && \
    make -j release

# samtools (includes htslib → bgzip, tabix)
RUN wget -q https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2 && \
    tar jxvf samtools-1.17.tar.bz2 && \
    cd samtools-1.17/htslib-1.17 && ./configure && make && make install && \
    cd ../ && ./configure --without-curses && make && make install && \
    cd /tools && rm -rf samtools-1.17 samtools-1.17.tar.bz2

# seqtk
WORKDIR /tools
RUN wget https://github.com/lh3/seqtk/archive/refs/tags/v1.4.tar.gz && \
    tar xvzf v1.4.tar.gz && \
    cd seqtk-1.4 && \
    make && \
    rm /tools/v1.4.tar.gz

ENV PATH="/tools/sedef:/tools/seqtk-1.4:${PATH}"

CMD ["/bin/bash"]
