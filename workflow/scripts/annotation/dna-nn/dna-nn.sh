#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
INPUT_ASSEMBLY_HAP1=$2
INPUT_ASSEMBLY_HAP2=$3
OUTPUT_DIR=$4

mkdir -p ${OUTPUT_DIR}

dna-brnn \
    -Ai /opt/dna-nn-0.1/models/attcc-alpha.knm \
    -t16 ${INPUT_ASSEMBLY_HAP1} \
| sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/${SAMPLE}.hap1_dna-brnn.bed

bgzip -f ${OUTPUT_DIR}/${SAMPLE}.hap1_dna-brnn.bed 
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.hap1_dna-brnn.bed.gz

dna-brnn \
    -Ai /opt/dna-nn-0.1/models/attcc-alpha.knm \
    -t16 ${INPUT_ASSEMBLY_HAP2} \
| sort -k 1,1 -k 2,2n > ${OUTPUT_DIR}/${SAMPLE}.hap2_dna-brnn.bed

bgzip -f ${OUTPUT_DIR}/${SAMPLE}.hap2_dna-brnn.bed
tabix -p bed ${OUTPUT_DIR}/${SAMPLE}.hap2_dna-brnn.bed.gz

echo ${?}
