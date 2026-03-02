FROM ubuntu:24.04

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

ENV DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends \
    r-base \
    gfortran \
    bzip2 \
    make \
    gcc \
    g++ \
    cmake \
    wget \
    ca-certificates \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libblas-dev \
    liblapack-dev \
    python3-pip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

WORKDIR /tools

RUN wget https://github.com/samtools/samtools/releases/download/1.17/samtools-1.17.tar.bz2 && \
    tar jxvf samtools-1.17.tar.bz2 && \
    cd samtools-1.17/htslib-1.17 && ./configure && make && make install && \
    cd ../ && ./configure --without-curses && make && make install

RUN wget https://github.com/logsdon-lab/NucFlag/archive/refs/tags/v0.3.3.zip && \
    unzip v0.3.3.zip && \
    cd NucFlag-0.3.3 && pip install --break-system-packages . && \
    pip3 install --break-system-packages -r requirements.txt

RUN wget -q https://github.com/mrvollger/NucFreq/archive/refs/tags/v0.1.zip && \
    unzip v0.1.zip && \
    pip3 install --break-system-packages numpy pysam pandas matplotlib seaborn


RUN Rscript -e "install.packages('ggplot2')" && \
    Rscript -e "install.packages('directlabels')" && \
    Rscript -e "install.packages('dplyr')" && \
    Rscript -e "install.packages('RColorBrewer')" && \
    Rscript -e "install.packages('reshape2')" && \
    Rscript -e "install.packages('tidyr')" && \
    Rscript -e "install.packages('ggsci')" && \
    Rscript -e "install.packages('zoo')"

CMD ["/bin/bash"]
