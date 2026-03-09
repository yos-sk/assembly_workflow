#!/bin/bash

set -eux -o pipefail

INPUT_FASTA=$1
OUTPUT_DIR=$2
hmm_profile=./db/AS-HORs-hmmer3.4-071024.hmm
hmm_profile_SF=./db/AS-SFs-hmmer3.0.290621.hmm

WORK_DIR=${OUTPUT_DIR}/work

mkdir -p ${WORK_DIR}

# alphaSat
run_hmmer() {
    f="$1"
    base_name=$(basename "$f" .fa)
    out_dir="${WORK_DIR}/alphaSat/${base_name}"
    mkdir -p "$out_dir"
    cp "$f" "$out_dir"

    ./hmmer-run.sh "$out_dir" "$hmm_profile" 8

    ./hmmer-run_SF.sh "$out_dir" "$hmm_profile_SF" 8
}

export -f run_hmmer
export WORK_DIR hmm_profile hmm_profile_SF
find ${WORK_DIR}/split -type f -name "*.fa" | xargs -n 1 -P 7 -I{} bash -c 'run_hmmer "$@"' _ {}


find ${WORK_DIR}/alphaSat/ -type f -name "AS-HOR-vs-*.bed" | while read f; do
    cat ${f} 
done | sort -k 1,1 -k2,2n > ${OUTPUT_DIR}/hor.bed

find ${WORK_DIR}/alphaSat/ -type f -name "AS-HOR+SF-vs-*.bed" | while read f; do
    cat ${f}
done | sort -k 1,1 -k2,2n > ${OUTPUT_DIR}/hor_sf.bed

find ${WORK_DIR}/alphaSat/ -type f -name "AS-SF-vs-*.bed" | while read f; do
    cat ${f}
done | sort -k 1,1 -k2,2n > ${OUTPUT_DIR}/sf.bed

find ${WORK_DIR}/alphaSat/ -type f -name "AS-strand-vs-*.bed" | while read f; do
    cat ${f}
done | sort -k 1,1 -k2,2n > ${OUTPUT_DIR}/strand.bed

echo ${?}
