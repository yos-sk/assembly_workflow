#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

HAP1_ASSEMBLY=$1
HAP2_ASSEMBLY=$2
HIC_READ1=$3
HIC_READ2=$4
OUTPUT_DIR=$5
THREADS=$6

PROJECT_DIR=$(pwd)

mkdir -p ${OUTPUT_DIR}
cd ${OUTPUT_DIR}
pstools phasing_error \
    -t ${THREADS} \
    ${PROJECT_DIR}/${HAP1_ASSEMBLY} \
    ${PROJECT_DIR}/${HAP2_ASSEMBLY} \
    ${HIC_READ1} \
    ${HIC_READ2} \
> phase_error_output.txt

echo ${?}
