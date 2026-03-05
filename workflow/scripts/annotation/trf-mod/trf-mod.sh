#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

if [ ${#} -ne 5 ]; then
    echo "Usage: $0 <sample> <assembler> <assembly_fasta> <output_dir> <trf_mod_bin>" >&2
    exit 1
fi

SAMPLE=$1
ASSEMBLER=$2
ASSEMBLY_FASTA=$3
OUTPUT_DIR=$4
TRF_MOD=$5

mkdir -p ${OUTPUT_DIR}
${TRF_MOD} \
    ${ASSEMBLY_FASTA} \
    -a 2 \
    -b 7 \
    -g 7 \
    -A 80 \
    -G 10 \
    -s 50 \
    -p 2000 \
    -l 30 \
> ${OUTPUT_DIR}/${SAMPLE}.trf-mod.bed

echo ${?}
