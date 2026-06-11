#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# hifiasm with trio binning.
# Parental short reads (pat/mat R1+R2) are always required; they become yak
# k-mer indices. ONT comes in two distinct roles:
#   - ${ONT}    : standard/simplex ONT, used as the ONT-only assembly base (--ont)
#   - ${ONT_UL} : ultra-long ONT, added to any assembly via --ul
# Supported input patterns (all + -1 pat.yak -2 mat.yak):
#   - HiFi (+ UL)      : hifiasm [--ul ${ONT_UL}]        ${HIFI}
#   - ONT-only (+ UL)  : hifiasm --ont [--ul ${ONT_UL}]  ${ONT}
# Pass an empty string (or "NA"/"-") for a read type that is not available.

SAMPLE=$1
ONT=$2
ONT_UL=$3
HIFI=$4
PAT_R1=$5
PAT_R2=$6
MAT_R1=$7
MAT_R2=$8
OUTPUT_DIR=$9
THREADS=${10:-56}

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

UL_OPT=""
if present "${ONT_UL}"; then
    UL_OPT="--ul ${ONT_UL}"
fi

if present "${HIFI}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        ${UL_OPT} \
        -1 ${WORK_DIR}/pat.yak \
        -2 ${WORK_DIR}/mat.yak \
        ${HIFI}
elif present "${ONT}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ont \
        ${UL_OPT} \
        -1 ${WORK_DIR}/pat.yak \
        -2 ${WORK_DIR}/mat.yak \
        ${ONT}
else
    echo "ERROR: provide HiFi or simplex ONT reads (ultra-long ONT alone cannot assemble)" >&2
    exit 1
fi

# Trio (dip) mode emits only hap1/hap2 graphs; there is no native primary set.
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.dip.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.dip.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa
# Combine both haplotypes into the diploid FASTA used as the "primary" output.
cat ${OUTPUT_DIR}/${SAMPLE}.hap1.fa ${OUTPUT_DIR}/${SAMPLE}.hap2.fa > ${OUTPUT_DIR}/${SAMPLE}.fa

echo ${?}
