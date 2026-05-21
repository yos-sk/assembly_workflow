#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

HAP1_ASSEMBLY=$(realpath "$1")
HAP2_ASSEMBLY=$(realpath "$2")
HIC_READ1=$(realpath "$3")
HIC_READ2=$(realpath "$4")
OUTPUT_DIR=$5
THREADS=$6

mkdir -p ${OUTPUT_DIR}
cd ${OUTPUT_DIR}
pstools phasing_error \
    -t ${THREADS} \
    ${HAP1_ASSEMBLY} \
    ${HAP2_ASSEMBLY} \
    ${HIC_READ1} \
    ${HIC_READ2} \
> phase_error_output.txt

echo ${?}
