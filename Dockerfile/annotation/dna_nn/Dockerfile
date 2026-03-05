# DNA-NN (DNA-BRNN) - Alpha satellite detection using deep learning

FROM ubuntu:22.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    git \
    bzip2 \
    libboost-all-dev \
    parallel \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install DNA-BRNN from source
WORKDIR /opt
RUN wget https://github.com/lh3/dna-nn/archive/refs/tags/v0.1.tar.gz && \
    tar xvzf v0.1.tar.gz && \
    cd dna-nn-0.1 && \
    make

# Install htslib for bgzip and tabix
WORKDIR /opt
RUN wget https://github.com/samtools/htslib/releases/download/1.17/htslib-1.17.tar.bz2 && \
    tar jxvf htslib-1.17.tar.bz2 && \
    cd htslib-1.17 && \
    ./configure  make && make install && \
    cd .. && \
    rm -rf htslib-1.19.1 htslib-1.19.1.tar.bz2

# Add dna-brnn to PATH
ENV PATH="/opt/dna-nn-0.1:${PATH}"


CMD ["/bin/bash"]
