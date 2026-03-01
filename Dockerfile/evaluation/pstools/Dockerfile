# pstools - Toolkit for fully phased sequences on chromosome level

FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"


ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

WORKDIR /tools

RUN apt-get update
RUN apt-get install -y \
  git \
  wget \
  make \
  g++ \
  zlib1g-dev \
  libbz2-dev 

RUN wget https://github.com/shilpagarg/pstools/archive/refs/tags/v0.2a3.tar.gz && \
    tar xvzf v0.2a3.tar.gz && cd pstools-0.2a3 && \
    make clean && make

ENV PATH $PATH:/tools/pstools-0.2a3
RUN pstools version

RUN wget https://github.com/lh3/minimap2/releases/download/v2.28/minimap2-2.28_x64-linux.tar.bz2 && \
    tar jxvf minimap2-2.28_x64-linux.tar.bz2

ENV PATH $PATH:/tools/minimap2-2.28_x64-linux
RUN minimap2 --version

CMD ["/bin/bash"]
