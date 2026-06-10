#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# hifiasm with Hi-C phasing.
# Hi-C R1/R2 are always required. The primary long-read input is flexible:
#   - HiFi + Hi-C        : hifiasm --h1 R1 --h2 R2              ${HIFI}
#   - ONT  + Hi-C        : hifiasm --ont --h1 R1 --h2 R2        ${ONT}
#   - HiFi + UL + Hi-C   : hifiasm --ul ${ONT} --h1 R1 --h2 R2  ${HIFI}
# Pass an empty string (or "NA"/"-") for a read type that is not available.
# NOTE: the ONT-only + Hi-C combination relies on hifiasm's --ont graph being
#       phased like the HiFi graph; validate output when first used.

SAMPLE=$1
ONT=$2
HIFI=$3
HIC_READ1=$4
HIC_READ2=$5
OUTPUT_DIR=$6
THREADS=${7:-56}

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

WORK_DIR=${OUTPUT_DIR}/workspace
mkdir -p ${WORK_DIR}
PREFIX=${WORK_DIR}/${SAMPLE}

if ! present "${HIC_READ1}" || ! present "${HIC_READ2}"; then
    echo "ERROR: Hi-C R1 and R2 are required for hifiasm_hic" >&2
    exit 1
fi

if present "${HIFI}" && present "${ONT}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ul ${ONT} \
        --h1 ${HIC_READ1} \
        --h2 ${HIC_READ2} \
        ${HIFI}
elif present "${HIFI}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --h1 ${HIC_READ1} \
        --h2 ${HIC_READ2} \
        ${HIFI}
elif present "${ONT}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ont \
        --h1 ${HIC_READ1} \
        --h2 ${HIC_READ2} \
        ${ONT}
else
    echo "ERROR: neither HiFi nor ONT reads were provided" >&2
    exit 1
fi

# Hi-C mode emits the .hic.* graphs.
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.hic.p_ctg.gfa    > ${OUTPUT_DIR}/${SAMPLE}.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.hic.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.hic.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa

echo ${?}