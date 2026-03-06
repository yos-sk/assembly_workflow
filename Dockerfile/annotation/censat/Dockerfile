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
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    python3 \
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
    cd bedtools2-2.31.0 && \
    make && \
    cp bin/* /usr/local/bin && \
    cd / && \
    rm -rf /opt/bedtools2-2.31.0

# Install htslib for bgzip and tabix
WORKDIR /opt
RUN wget https://github.com/samtools/htslib/releases/download/1.17/htslib-1.17.tar.bz2 && \
    tar jxvf htslib-1.17.tar.bz2 && \
    cd htslib-1.17 && \
    ./configure && make && make install && \
    cd .. && \
    rm -rf htslib-1.17 htslib-1.17.tar.bz2

ENV PATH="/opt/seqtk-1.4:${PATH}"

CMD ["/bin/bash"]
