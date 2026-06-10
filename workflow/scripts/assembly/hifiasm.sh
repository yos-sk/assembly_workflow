#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# hifiasm without phasing info (no Hi-C / no trio).
# Supports three input patterns and auto-selects the command:
#   - HiFi only         : hifiasm                ${HIFI}
#   - ONT only (R10)    : hifiasm --ont          ${ONT}
#   - HiFi + ultralong  : hifiasm --ul ${ONT}    ${HIFI}
# Pass an empty string (or "NA"/"-") for a read type that is not available.

SAMPLE=$1
ONT=$2
HIFI=$3
OUTPUT_DIR=$4
THREADS=${5:-56}

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

WORK_DIR=${OUTPUT_DIR}/workspace
mkdir -p ${WORK_DIR}
PREFIX=${WORK_DIR}/${SAMPLE}

if present "${HIFI}" && present "${ONT}"; then
    # HiFi assembly augmented with ultra-long ONT reads.
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ul ${ONT} \
        ${HIFI}
elif present "${HIFI}"; then
    # HiFi-only assembly.
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        ${HIFI}
elif present "${ONT}"; then
    # ONT-only assembly (ONT R10 simplex reads; requires hifiasm >= 0.24).
    hifiasm \
        -o ${PREFIX} \
        -t ${THREADS} \
        --ont \
        ${ONT}
else
    echo "ERROR: neither HiFi nor ONT reads were provided" >&2
    exit 1
fi

# All non-phased modes emit the .bp.* graphs.
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.bp.p_ctg.gfa    > ${OUTPUT_DIR}/${SAMPLE}.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.bp.hap1.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap1.fa
awk '/^S/{print ">"$2;print $3}' ${PREFIX}.bp.hap2.p_ctg.gfa > ${OUTPUT_DIR}/${SAMPLE}.hap2.fa

echo ${?}