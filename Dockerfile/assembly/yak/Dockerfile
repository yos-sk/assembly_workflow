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

# Install YAK (v0.1)
WORKDIR /opt
RUN wget https://github.com/lh3/yak/archive/refs/tags/v0.1.tar.gz && \
    tar xvzf v0.1.tar.gz && \
    cd yak-0.1 && \
    make && \
    ln -s /opt/yak-0.1/yak /usr/local/bin/yak

CMD ["/bin/bash"]
