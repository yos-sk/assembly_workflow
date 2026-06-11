#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# verkko with trio binning.
# --hifi (HiFi / ONT-Duplex / HERRO-corrected) is required; ultra-long ONT
# (${ONT_UL}, the sample sheet `ont_ul` column) feeds --nano and is optional.
# Parental hapmers are pre-built by verkko_trio_prep.sh and read from
# ${OUTPUT_DIR}/hapmers/. The parental read paths ($5-$8) are accepted for
# interface compatibility but are not used here.

OUTPUT_DIR=$1
SAMPLE=$2
ONT_UL=$3
HIFI=$4
PAT_R1=$5
PAT_R2=$6
MAT_R1=$7
MAT_R2=$8

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

if ! present "${HIFI}"; then
    echo "ERROR: --hifi input (HiFi / ONT-Duplex / HERRO-corrected) is required for verkko" >&2
    exit 1
fi

NANO_OPT=""
if present "${ONT_UL}"; then
    NANO_OPT="--nano ${ONT_UL}"
fi

verkko \
    -d ${OUTPUT_DIR} \
    --hifi ${HIFI} \
    ${NANO_OPT} \
    --hap-kmers ${OUTPUT_DIR}/hapmers/paternal_compress.k30.hapmer.only.meryl \
                ${OUTPUT_DIR}/hapmers/maternal_compress.k30.hapmer.only.meryl \
                trio \
    --screen-human-contaminants

echo ${?}
