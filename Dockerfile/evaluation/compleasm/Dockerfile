FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    bzip2 \
    python3 \
    python3-pip \
    hmmer \
    && rm -rf /var/lib/apt/lists/*

# Install miniprot (required by compleasm)
WORKDIR /opt
RUN wget https://github.com/lh3/miniprot/releases/download/v0.13/miniprot-0.13_x64-linux.tar.bz2 && \
    tar jxvf miniprot-0.13_x64-linux.tar.bz2 && \
    cp miniprot-0.13_x64-linux/miniprot /usr/local/bin/ && \
    rm -rf miniprot-0.13_x64-linux.tar.bz2 miniprot-0.13_x64-linux

# Install compleasm (pre-compiled binary)
WORKDIR /opt
RUN wget https://github.com/huangnengCSU/compleasm/releases/download/v0.2.6/compleasm-0.2.6_x64-linux.tar.bz2 && \
    tar jxvf compleasm-0.2.6_x64-linux.tar.bz2 && \
    rm compleasm-0.2.6_x64-linux.tar.bz2

ENV PATH="/opt/compleasm-0.2.6_x64-linux:${PATH}"

CMD ["/bin/bash"]
