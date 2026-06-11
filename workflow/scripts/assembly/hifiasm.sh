#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# hifiasm without phasing info (no Hi-C / no trio).
# ONT comes in two distinct roles:
#   - ${ONT}    : standard/simplex ONT, used as the ONT-only assembly base (--ont)
#   - ${ONT_UL} : ultra-long ONT, added to any assembly via --ul
# Supported input patterns:
#   - HiFi (+ UL)      : hifiasm [--ul ${ONT_UL}]        ${HIFI}
#   - ONT-only (+ UL)  : hifiasm --ont [--ul ${ONT_UL}]  ${ONT}
# Pass an empty string (or "NA"/"-") for a read type that is not available.

SAMPLE=$1
ONT=$2
ONT_UL=$3
HIFI=$4
OUTPUT_DIR=$5
THREADS=${6:-56}

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

WORK_DIR=${OUTPUT_DIR}/workspace
mkdir -p ${WORK_DIR}
PREFIX=${WORK_DIR}/${SAMPLE}

UL_OPT=""
if present "${ONT_UL}"; then
    UL_OPT="--ul ${ONT_UL}"
fi

if present "${HIFI}"; then
    # HiFi assembly (optionally augmented with ultra-long ONT).
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        ${UL_OPT} \
        ${HIFI}
elif present "${ONT}"; then
    # ONT-only assembly (ONT R10 simplex; optionally augmented with ultra-long ONT).
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ont \
        ${UL_OPT} \
        ${ONT}
else
    echo "ERROR: provide HiFi or simplex ONT reads (ultra-long ONT alone cannot assemble)" >&2
    exit 1
fi

# All non-phased modes emit the .bp.* graphs.
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.bp.p_ctg.gfa    > ${OUTPUT_DIR}/${SAMPLE}.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.bp.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.bp.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa

echo ${?}
