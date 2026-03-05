#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

OUTPUT_DIR=$1
ONT=$2
HIFI=$3
HIC_READ1=$4
HIC_READ2=$5

verkko \
    -d ${OUTPUT_DIR}\
    --hifi ${HIFI} \
    --nano ${ONT} \
    --hic1 ${HIC_READ1} \
    --hic2 ${HIC_READ2} \
    --screen-human-contaminants

echo ${?}
