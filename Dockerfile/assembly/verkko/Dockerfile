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
    conda create -n verkko -c conda-forge -c bioconda -c defaults verkko=2.2.1 blis 'networkx<=3.2.1'

ENV PATH /opt/miniconda3/envs/verkko/bin:$PATH

RUN verkko --version

# verkko 2.2.1's Hi-C/Pore-C phasing (scripts/cluster.py) accesses the networkx
# submodule attribute `community.kernighan_lin.kernighan_lin_bisection`. networkx
# exposes it through 3.2.x but dropped it in later 3.x (e.g. 3.6.1 -> AttributeError).
# Guard the actual capability verkko needs, not a version number.
RUN python -c "import networkx; print('networkx', networkx.__version__); import networkx.algorithms.community as c; c.kernighan_lin.kernighan_lin_bisection"

CMD ["/bin/bash"]
