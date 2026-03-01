FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    wget \
    git \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install hifiasm (v0.19.9)
WORKDIR /opt
RUN wget https://github.com/chhylp123/hifiasm/archive/refs/tags/0.25.0.tar.gz && \
    tar xvzf 0.25.0.tar.gz && \
    cd hifiasm-0.25.0 && \
    make && \
    ln -s /opt/hifiasm-0.25.0/hifiasm /usr/local/bin/hifiasm

CMD ["/bin/bash"]
