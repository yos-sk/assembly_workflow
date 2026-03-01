FROM ubuntu:20.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y \
    sudo \
    wget \
    git \
    bc

RUN sudo ln -sf /bin/bash /bin/sh
    
ENV PATH /opt/miniconda3/bin:$PATH

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    sh Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3 && \
    rm -r Miniconda3-latest-Linux-x86_64.sh && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    conda update -n base -c defaults conda && \
    conda init && \
    conda create -n verkko -c conda-forge -c bioconda -c defaults verkko=2.2.1 blis 

ENV PATH /opt/miniconda3/envs/verkko/bin:$PATH

RUN verkko --version

CMD ["/bin/bash"]
