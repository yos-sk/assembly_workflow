#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

OUTPUT_DIR=$1
SAMPLE=$2
ONT=$2
HIFI=$3
PAT_R1=$4
PAT_R2=$5
MAT_R1=$6
MAT_R2=$7
OUTPUT_DIR=$8

verkko \
    -d ${OUTPUT_DIR} \
    --hifi ${HIFI} \
    --nano ${ONT} \
    --hap-kmers ${OUTPUT_DIR}/paternal_compress.k30.hapmer.only.meryl \
                ${OUTPUT_DIR}/maternal_compress.k30.hapmer.only.meryl \
                trio \
    --screen-human-contaminants 

echo ${?}
