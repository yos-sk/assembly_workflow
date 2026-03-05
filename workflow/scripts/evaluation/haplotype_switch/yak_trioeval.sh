#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

PAT_R1=$1
PAT_R2=$2
MAT_R1=$3
MAT_R2=$4
ASSEMBLY_PAT=$5
ASSEMBLY_MAT=$6
OUTPUT_DIR=$7

mkdir -p ${OUTPUT_DIR}

yak count -b37 -t32 -o ${OUTPUT_DIR}/pat.yak <(zcat ${PAT_R1} ${PAT_R2}) <(zcat ${PAT_R1} ${PAT_R2})
yak count -b37 -t32 -o ${OUTPUT_DIR}/mat.yak <(zcat ${MAT_R1} ${MAT_R2}) <(zcat ${MAT_R1} ${MAT_R2})
yak trioeval -t 32 ${OUTPUT_DIR}/pat.yak ${OUTPUT_DIR}/mat.yak ${ASSEMBLY_PAT} > ${OUTPUT_DIR}/paternal.yak_phasing.txt
åyak trioeval -t 32 ${OUTPUT_DIR}/pat.yak ${OUTPUT_DIR}/mat.yak ${ASSEMBLY_MAT} > ${OUTPUT_DIR}/maternal.yak_phasing.txt

echo ${?}
