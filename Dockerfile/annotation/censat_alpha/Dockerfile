# CenSat Alpha annotation (AlphaSat + HMMER)

FROM juklucas/alphasat_hmmer@sha256:7210a50bc6a99a8beea374f689753e2e6d16b02dc60b400b40694a9ca6ce2489

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"

# Install bedtools
WORKDIR /opt
RUN apt-get update && apt-get install -y \
    wget \
    make \
    g++ \
    zlib1g-dev \
    libbz2-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/* && \
    wget https://github.com/arq5x/bedtools2/archive/v2.31.0.tar.gz && \
    tar zxvf v2.31.0.tar.gz && \
    rm v2.31.0.tar.gz && \
    cd bedtools2-2.31.0 && \
    make && \
    cp bin/* /usr/local/bin && \
    cd / && \
    rm -rf /opt/bedtools2-2.31.0

CMD ["/bin/bash"]
