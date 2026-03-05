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


mkdir -p ${OUTPUT_DIR}
pstools phasing_error \
    -t 56 \
    ${HAP1_ASSEMBLY} \
    ${HAP2_ASSEMBLY} \
    ${HIC_READ1} \
    ${HIC_READ2} \
> ${OUTPUT_DIR}/phase_error_output.txt

mv hic_connection_in_haps.txt ${OUTPUT_DIR} 

echo ${?}
