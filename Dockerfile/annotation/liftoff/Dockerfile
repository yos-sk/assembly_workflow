FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    git \
    python3 \
    python3-pip \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Install minimap2
WORKDIR /opt
RUN wget https://github.com/lh3/minimap2/releases/download/v2.28/minimap2-2.28_x64-linux.tar.bz2 && \
    tar -xjf minimap2-2.28_x64-linux.tar.bz2 && \
    ln -s /opt/minimap2-2.28_x64-linux/minimap2 /usr/local/bin/minimap2 && \
    rm minimap2-2.28_x64-linux.tar.bz2

# Install Python packages including Liftoff
RUN pip3 install --no-cache-dir \
    "numpy<1.24" \
    pandas \
    biopython \
    pysam \
    gffutils \
    liftoff==1.6.3.2

# Install gffread
WORKDIR /opt
RUN wget https://github.com/gpertea/gffread/archive/refs/tags/v0.12.7.tar.gz && \
    tar xvzf v0.12.7.tar.gz && \
    cd gffread-0.12.7 && \
    make release && \
    ln -s /opt/gffread-0.12.7/gffread /usr/local/bin/gffread

# Install htslib (bgzip, tabix)
WORKDIR /opt
RUN wget https://github.com/samtools/htslib/releases/download/1.17/htslib-1.17.tar.bz2 && \
    tar -xjf htslib-1.17.tar.bz2 && \
    cd htslib-1.17 && \
    ./configure && \
    make && \
    make install && \
    cd /opt && \
    rm -rf htslib-1.17.tar.bz2


CMD ["/bin/bash"]
