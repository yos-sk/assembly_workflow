#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# hifiasm with trio binning.
# Parental short reads (pat/mat R1+R2) are always required; they are converted
# to yak k-mer indices. The primary long-read input is flexible:
#   - HiFi + trio        : hifiasm -1 pat.yak -2 mat.yak              ${HIFI}
#   - ONT  + trio        : hifiasm --ont -1 pat.yak -2 mat.yak        ${ONT}
#   - HiFi + UL + trio   : hifiasm --ul ${ONT} -1 pat.yak -2 mat.yak  ${HIFI}
# Pass an empty string (or "NA"/"-") for a read type that is not available.
# NOTE: the ONT-only + trio combination relies on hifiasm's --ont graph being
#       binnable like the HiFi graph; validate output when first used.

SAMPLE=$1
ONT=$2
HIFI=$3
PAT_R1=$4
PAT_R2=$5
MAT_R1=$6
MAT_R2=$7
OUTPUT_DIR=$8
THREADS=${9:-56}

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

WORK_DIR=${OUTPUT_DIR}/workspace
mkdir -p ${WORK_DIR}
PREFIX=${WORK_DIR}/${SAMPLE}

for f in "${PAT_R1}" "${PAT_R2}" "${MAT_R1}" "${MAT_R2}"; do
    present "${f}" || { echo "ERROR: trio requires paternal/maternal R1 and R2" >&2; exit 1; }
done

# Build parental k-mer indices. Reads are passed twice because process
# substitution streams cannot be rewound for yak's two-pass counting.
yak count -b37 -t ${THREADS} -o ${WORK_DIR}/pat.yak <(cat ${PAT_R1} ${PAT_R2}) <(cat ${PAT_R1} ${PAT_R2})
yak count -b37 -t ${THREADS} -o ${WORK_DIR}/mat.yak <(cat ${MAT_R1} ${MAT_R2}) <(cat ${MAT_R1} ${MAT_R2})

if present "${HIFI}" && present "${ONT}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ul ${ONT} \
        -1 ${WORK_DIR}/pat.yak \
        -2 ${WORK_DIR}/mat.yak \
        ${HIFI}
elif present "${HIFI}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        -1 ${WORK_DIR}/pat.yak \
        -2 ${WORK_DIR}/mat.yak \
        ${HIFI}
elif present "${ONT}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ont \
        -1 ${WORK_DIR}/pat.yak \
        -2 ${WORK_DIR}/mat.yak \
        ${ONT}
else
    echo "ERROR: neither HiFi nor ONT reads were provided" >&2
    exit 1
fi

# Trio (dip) mode emits only hap1/hap2 graphs; there is no native primary set.
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.dip.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.dip.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa
# Combine both haplotypes into the diploid FASTA used as the "primary" output.
cat ${OUTPUT_DIR}/${SAMPLE}.hap1.fa ${OUTPUT_DIR}/${SAMPLE}.hap2.fa > ${OUTPUT_DIR}/${SAMPLE}.fa

echo ${?}