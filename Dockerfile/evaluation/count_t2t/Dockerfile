FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    git \
    autoconf \
    automake \
    libtool \
    libbz2-dev \
    liblzma-dev \
    libgsl-dev \
    zlib1g-dev \
    pkg-config \
    cmake \
    python3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# htslib
RUN wget https://github.com/samtools/htslib/releases/download/1.17/htslib-1.17.tar.bz2 && \
    tar jxvf htslib-1.17.tar.bz2 && \
    cd htslib-1.17 && \
    ./configure && \
    make && make install && \
    cd .. && rm htslib-1.17.tar.bz2 

WORKDIR /tools

RUN wget https://github.com/marbl/MashMap/archive/refs/tags/v3.1.3.tar.gz && \
    tar xvzf v3.1.3.tar.gz && \
    cd MashMap-3.1.3 && \
    cmake -H. -Bbuild -DCMAKE_BUILD_TYPE=Release && \
    cmake --build build

# seqtk
RUN wget https://github.com/lh3/seqtk/archive/refs/tags/v1.4.tar.gz && \
    tar xvzf v1.4.tar.gz && \
    cd seqtk-1.4 && \
    make

ENV PATH=/tools/MashMap-3.1.3/build/bin:$PATH
ENV PATH=/tools/seqtk-1.4:$PATH

CMD ["/bin/bash"]
