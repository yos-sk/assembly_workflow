#!/bin/bash

set -eux -o pipefail

OUTPUT_DIR=$1

WORK_DIR=${OUTPUT_DIR}/work

find ${WORK_DIR}/rDNA/ -type f -name "*.sorted.bed" | while read f; do
    cat ${f}
done | bedtools sort -i stdin > ${WORK_DIR}/rDNA/rDNA.bed
bedtools merge -d 50000 -i ${WORK_DIR}/rDNA/rDNA.bed > ${WORK_DIR}/rDNA/rDNA.merged.bed

sed 's/$/\trDNA\t0\t.\t.\t.\t102,47,144/' ${WORK_DIR}/rDNA/rDNA.merged.bed > ${OUTPUT_DIR}/rDNA.bed
awk '$7=$2' OFS='\t' ${OUTPUT_DIR}/rDNA.bed | awk '$8=$3' OFS='\t' > ${OUTPUT_DIR}/rDNA_tmp.bed && mv ${OUTPUT_DIR}/rDNA_tmp.bed ${OUTPUT_DIR}/rDNA.bed

echo ${?}