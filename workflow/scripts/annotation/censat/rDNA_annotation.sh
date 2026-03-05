#!/bin/bash

set -eux -o pipefail

INPUT_FASTA=$1
OUTPUT_DIR=$2
hmm_profile_rDNA=./db/rDNA1.0.hmm

WORK_DIR=${OUTPUT_DIR}/work

run_hmmer_rDNA() {
    f="$1"
    base_name=$(basename "$f" .fa)
    output_prefix="${WORK_DIR}/rDNA/${base_name}"
    nhmmer --cpu 8 --notextw --noali --tblout ${output_prefix}.out -o /dev/null ${hmm_profile_rDNA} ${f}
    awk -v th=0.7 -f /opt/HumAS-HMMER_for_AnVIL/hmmertblout2bed.awk ${output_prefix}.out > ${output_prefix}.bed || echo -e 'chrFAKE\t0\t1' > ${output_prefix}.bed
    sort -k 1.4,1 -k 2,2n ${output_prefix}.bed > ${output_prefix}.sorted.bed

}
export -f run_hmmer_rDNA
export WORK_DIR hmm_profile_rDNA
mkdir -p ${WORK_DIR}/rDNA
find ${WORK_DIR}/split -type f -name "*.fa" | xargs -n 1 -P 3 -I{} bash -c 'run_hmmer_rDNA "$@"' _ {}

find ${WORK_DIR}/rDNA/ -type f -name "*.sorted.bed" | while read f; do
    cat ${f}
done | bedtools sort -i stdin > ${WORK_DIR}/rDNA/rDNA.bed
bedtools merge -d 50000 -i  ${WORK_DIR}/rDNA/rDNA.bed > ${WORK_DIR}/rDNA/rDNA.merged.bed

# filtering out anything smaller than 10kb
sed 's/$/\trDNA\t0\t.\t.\t.\t102,47,144/' ${WORK_DIR}/rDNA/rDNA.merged.bed > ${OUTPUT_DIR}/rDNA.bed
awk '$7=$2' OFS='\t' ${OUTPUT_DIR}/rDNA.bed | awk '$8=$3' OFS='\t' > ${OUTPUT_DIR}/rDNA_tmp.bed && mv ${OUTPUT_DIR}/rDNA_tmp.bed ${OUTPUT_DIR}/rDNA.bed

echo ${?}
