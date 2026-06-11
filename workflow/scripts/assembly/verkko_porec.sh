#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# verkko with Pore-C phasing.
# --hifi (HiFi / ONT-Duplex / HERRO-corrected) and Pore-C reads are required;
# ultra-long ONT (${ONT_UL}, the sample sheet `ont_ul` column) feeds --nano and
# is optional.

OUTPUT_DIR=$1
HIFI=$2
ONT_UL=$3
POREC=$4

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

if ! present "${HIFI}"; then
    echo "ERROR: --hifi input (HiFi / ONT-Duplex / HERRO-corrected) is required for verkko" >&2
    exit 1
fi
if ! present "${POREC}"; then
    echo "ERROR: Pore-C reads are required for verkko_porec" >&2
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
    --porec ${POREC} \
    --screen-human-contaminants

echo ${?}
