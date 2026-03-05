# CenSat annotation 

FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    tar \
    make \
    cmake \
    g++ \
    libjsoncpp-dev \
    pkg-config \
    zlib1g-dev  \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install seqtk
WORKDIR /opt
# seqtk
RUN wget https://github.com/lh3/seqtk/archive/refs/tags/v1.4.tar.gz && \
    tar xvzf v1.4.tar.gz && \
    cd seqtk-1.4 && \
    make

# bedtools
RUN wget https://github.com/arq5x/bedtools2/archive/v2.31.0.tar.gz && \
    tar zxvf v2.31.0.tar.gz && \
    rm v2.31.0.tar.gz && \
    cd bedtools2-v2.31.0 && \
    make && \
    cp bin/* /usr/local/bin && \
    cd / && \
    rm -rf bedtools2-${BEDTOOLS_VER}

CMD ["/bin/bash"]
