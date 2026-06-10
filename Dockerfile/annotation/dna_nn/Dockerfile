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
    bzip2 \
    curl \
    libboost-all-dev \
    parallel \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install dna-brnn from source
WORKDIR /opt
RUN wget https://github.com/lh3/dna-nn/archive/refs/tags/v0.1.tar.gz && \
    tar xvzf v0.1.tar.gz && \
    cd dna-nn-0.1 && \
    make

# Add dna-brnn to PATH
ENV PATH="/opt/dna-nn-0.1:${PATH}"

# Install htslib for bgzip and tabix
WORKDIR /opt
RUN wget https://github.com/samtools/htslib/releases/download/1.17/htslib-1.17.tar.bz2 && \
    tar jxvf htslib-1.17.tar.bz2 && \
    cd htslib-1.17 && \
    ./configure && make && make install && \
    cd .. && \
    rm -rf htslib-1.17 htslib-1.17.tar.bz2

# Install samtools
WORKDIR /opt
RUN wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2 && \
    tar jxvf samtools-1.17.tar.bz2 && \
    cd samtools-1.17 && \
    ./configure --without-curses && make && make install && \
    cd .. && \
    rm -rf samtools-1.17 samtools-1.17.tar.bz2

# Install minimap2 (prebuilt binary)
WORKDIR /opt
RUN wget https://github.com/lh3/minimap2/releases/download/v2.28/minimap2-2.28_x64-linux.tar.bz2 && \
    tar jxvf minimap2-2.28_x64-linux.tar.bz2 && \
    cp minimap2-2.28_x64-linux/minimap2 /usr/local/bin/ && \
    rm -rf minimap2-2.28_x64-linux.tar.bz2 minimap2-2.28_x64-linux

# Install bedtools
WORKDIR /opt
RUN wget https://github.com/arq5x/bedtools2/releases/download/v2.31.0/bedtools-2.31.0.tar.gz && \
    tar zxvf bedtools-2.31.0.tar.gz && \
    rm bedtools-2.31.0.tar.gz && \
    cd bedtools2 && \
    make && \
    cp bin/* /usr/local/bin && \
    cd / && \
    rm -rf /opt/bedtools2

# Install seqtk (length filtering in the assembly filter step)
WORKDIR /opt
RUN wget https://github.com/lh3/seqtk/archive/refs/tags/v1.5.tar.gz && \
    tar zxvf v1.5.tar.gz && \
    cd seqtk-1.5 && \
    make && \
    cp seqtk /usr/local/bin/ && \
    cd /opt && \
    rm -rf seqtk-1.5 v1.5.tar.gz

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install fastq_checker
# Install to /usr/local so it's reachable when singularity runs the container
# as a non-root host user (the default /root/.cargo/bin path is mode 0700 and
# inaccessible to non-root).
WORKDIR /opt
RUN git clone https://github.com/yos-sk/fastq_checker.git && \
    cd fastq_checker && \
    git checkout 5a15f6a && \
    cargo install --path . --root /usr/local && \
    rm -rf /opt/fastq_checker

CMD ["/bin/bash"]
