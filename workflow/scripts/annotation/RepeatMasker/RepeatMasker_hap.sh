#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

export BLASTDB_LMDB_MAP_SIZE=100000000

ASSEMBLY_FASTA=$1
OUTPUT_DIR=$2
THREADS=$3

mkdir -p ${OUTPUT_DIR}
RepeatMasker \
    -species human \
    -e rmblast \
    -pa ${THREADS} \
    ${ASSEMBLY_FASTA} \
    -dir ${OUTPUT_DIR}

echo ${?}
