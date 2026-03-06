# Chaintools - Utilities for the genomic chain format

FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    cmake \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tools

# Dependency of chaintools
RUN pip3 install intervaltree pandas pysam

# chaintools 
RUN git clone https://github.com/yos-sk/chaintools.git && \
    cd chaintools && \
    git checkout 2a3b47e

# Install Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# rustybam
RUN wget https://github.com/vollgerlab/rustybam/archive/refs/tags/v0.2.0.tar.gz && \
    tar xvzf v0.2.0.tar.gz && \
    cd rustybam-0.2.0 && \
    cargo build --release

# paf2chain
RUN wget https://github.com/AndreaGuarracino/paf2chain/archive/refs/tags/v0.1.1.tar.gz && \
    tar xvzf v0.1.1.tar.gz && \
    cd paf2chain-0.1.1 && \
    cargo build --release

ENV PATH="${PATH}:/tools/rustybam-0.2.0/target/release"
ENV PATH="${PATH}:/tools/paf2chain-0.1.1/target/release"

CMD ["/bin/bash"]
