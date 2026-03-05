#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

INPUT_HIFI_FASTQ=$1
OUTPUT_DIR=$2
SAMPLE=$3
THREADS=$4

mkdir -p ${OUTPUT_DIR}

yak count -t ${THREADS} -b37 -o ${OUTPUT_DIR}/${SAMPLE}.pb.yak ${INPUT_HIFI_FASTQ}

echo ${?}

