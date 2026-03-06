# TEtools - Transposable Element annotation tools
# Includes RepeatMasker and associated tools

FROM dfam/tetools:1.88.5

LABEL maintainer="Yoshitaka Sakamoto <yosakam2@gmail.com>"
LABEL description="TEtools with RepeatMasker for repeat annotation"

ENV TZ=Asia/Tokyo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# TEtools already includes:
# - RepeatMasker
# - RepeatModeler
# - Dfam library
# - RMBlast
# - TRF (Tandem Repeats Finder)
# - CD-HIT
# - MAFFT
# - genometools
# - LTR retriever
# - NINJA
# - RECON
# - RepeatScout
# - UCSC tools

# Install additional Python packages
RUN apt-get update && apt-get install -y python3-pip && \
    pip3 install --break-system-packages pandas numpy biopython && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /data

CMD ["/bin/bash"]
