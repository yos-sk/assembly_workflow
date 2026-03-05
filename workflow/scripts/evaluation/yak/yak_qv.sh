#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

INPUT_ASSEMBLY_HAP1=$1
INPUT_ASSEMBLY_HAP2=$2
YAK_COUNT_FILE=$3
OUTPUT_DIR=$3
SAMPLE=$4
THREADS=$5

yak qv -t ${THREADS} -p -K3.2g -l100k ${YAK_COUNT_FILE} ${INPUT_ASSEMBLY_HAP1} > ${OUTPUT_DIR}/${SAMPLE}.hap1.pb.yak.qv.txt
yak qv -t ${THREADS} -p -K3.2g -l100k ${YAK_COUNT_FILE}  ${INPUT_ASSEMBLY_HAP2} > ${OUTPUT_DIR}/${SAMPLE}.hap2.pb.yak.qv.txt

echo ${?}
