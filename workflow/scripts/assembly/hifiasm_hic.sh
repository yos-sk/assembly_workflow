#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# hifiasm with Hi-C phasing.
# Hi-C R1/R2 are always required. ONT comes in two distinct roles:
#   - ${ONT}    : standard/simplex ONT, used as the ONT-only assembly base (--ont)
#   - ${ONT_UL} : ultra-long ONT, added to any assembly via --ul
# Supported input patterns (all + --h1/--h2):
#   - HiFi (+ UL)      : hifiasm [--ul ${ONT_UL}] --h1 R1 --h2 R2        ${HIFI}
#   - ONT-only (+ UL)  : hifiasm --ont [--ul ${ONT_UL}] --h1 R1 --h2 R2  ${ONT}
# Pass an empty string (or "NA"/"-") for a read type that is not available.

SAMPLE=$1
ONT=$2
ONT_UL=$3
HIFI=$4
HIC_READ1=$5
HIC_READ2=$6
OUTPUT_DIR=$7
THREADS=${8:-56}

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

WORK_DIR=${OUTPUT_DIR}/workspace
mkdir -p ${WORK_DIR}
PREFIX=${WORK_DIR}/${SAMPLE}

if ! present "${HIC_READ1}" || ! present "${HIC_READ2}"; then
    echo "ERROR: Hi-C R1 and R2 are required for hifiasm_hic" >&2
    exit 1
fi

UL_OPT=""
if present "${ONT_UL}"; then
    UL_OPT="--ul ${ONT_UL}"
fi

if present "${HIFI}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        ${UL_OPT} \
        --h1 ${HIC_READ1} \
        --h2 ${HIC_READ2} \
        ${HIFI}
elif present "${ONT}"; then
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ont \
        ${UL_OPT} \
        --h1 ${HIC_READ1} \
        --h2 ${HIC_READ2} \
        ${ONT}
else
    echo "ERROR: provide HiFi or simplex ONT reads (ultra-long ONT alone cannot assemble)" >&2
    exit 1
fi

# Hi-C mode emits the .hic.* graphs.
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.hic.p_ctg.gfa    > ${OUTPUT_DIR}/${SAMPLE}.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.hic.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.hic.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa

echo ${?}
