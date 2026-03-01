# Image for alignment

FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"
LABEL description="Base image with common bioinformatics tools"

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    curl \
    git \
    autoconf \
    automake \
    make \
    gcc \
    g++ \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-gnutls-dev \
    libssl-dev \
    libncurses5-dev \
    && rm -rf /var/lib/apt/lists/*

# Install minimap2 (v2.28)
WORKDIR /opt
RUN wget https://github.com/lh3/minimap2/releases/download/v2.28/minimap2-2.28_x64-linux.tar.bz2 && \
    tar -xjf minimap2-2.28_x64-linux.tar.bz2 && \
    ln -s /opt/minimap2-2.28_x64-linux/minimap2 /usr/local/bin/minimap2 && \
    rm minimap2-2.28_x64-linux.tar.bz2

# Install samtools (v1.17)
RUN wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2 && \
    tar jxvf samtools-1.17.tar.bz2 && \
    cd samtools-1.17/htslib-1.17 && ./configure && make && make install && \
    cd ../ && ./configure --without-curses && make && make install


# Default command
CMD ["/bin/bash"]
