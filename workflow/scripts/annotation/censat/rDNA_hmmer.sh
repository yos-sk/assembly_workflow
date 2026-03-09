#!/bin/bash

set -eux -o pipefail

INPUT_FASTA=$1
OUTPUT_DIR=$2
HMM_PROFILE=$3

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
export WORK_DIR
export hmm_profile_rDNA=${HMM_PROFILE}
mkdir -p ${WORK_DIR}/rDNA
find ${WORK_DIR}/split -type f -name "*.fa" | xargs -n 1 -P 3 -I{} bash -c 'run_hmmer_rDNA "$@"' _ {}

echo ${?}