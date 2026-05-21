#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

ILLUMINA_READ1=$1
ILLUMINA_READ2=$2
ASSEMBLY_FASTA_HAP1=$3
ASSEMBLY_FASTA_HAP2=$4
MERQURY_DB=$5
OUTPUT_DIR=$6
THREADS=$7
MEMORY_MB=$8

PROJECT_DIR=$(pwd)

# Convert mem_mb to GB with headroom for meryl memory cap
MEMORY_GB=$(( MEMORY_MB / 1024 - 10 ))

mkdir -p ${MERQURY_DB}
if [ ! -d ${MERQURY_DB}/READS_DB.meryl ]; then
    meryl k=21 count memory=${MEMORY_GB} threads=${THREADS} ${ILLUMINA_READ1} ${ILLUMINA_READ2} output ${MERQURY_DB}/READS_DB.meryl
fi

MERQURY_DB_DIR=$(cd ${MERQURY_DB} && pwd)
mkdir -p ${OUTPUT_DIR}

export MERQURY=/tools/merqury
cd ${OUTPUT_DIR}
/tools/merqury/merqury.sh ${MERQURY_DB_DIR}/READS_DB.meryl ${PROJECT_DIR}/${ASSEMBLY_FASTA_HAP1} ${PROJECT_DIR}/${ASSEMBLY_FASTA_HAP2} out

echo ${?}

