#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

SAMPLE=$1
ASSEMBLY_FASTA_HAP1=$2
ASSEMBLY_FASTA_HAP2=$3
OUTPUT_DIR=$4
THREADS=$5
LIBRARY=$6

compleasm run \
    --mode busco \
    -L ${LIBRARY} \
    -l primates_odb10 \
    --threads ${THREADS} \
    -o ${OUTPUT_DIR}/hp1 \
    -a ${ASSEMBLY_FASTA_HAP1}

compleasm run \
    --mode busco \
    -L ${LIBRARY} \
    -l primates_odb10 \
    --threads ${THREADS} \
    -o ${OUTPUT_DIR}/hp2 \
    -a ${ASSEMBLY_FASTA_HAP2}

echo ${?}
