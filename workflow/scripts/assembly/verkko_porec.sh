#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# verkko with Pore-C phasing.
# --hifi (HiFi / ONT-Duplex / HERRO-corrected) and Pore-C reads are required;
# ultra-long ONT via --nano is optional.

OUTPUT_DIR=$1
HIFI=$2
ONT=$3
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
if present "${ONT}"; then
    NANO_OPT="--nano ${ONT}"
fi

verkko \
    -d ${OUTPUT_DIR} \
    --hifi ${HIFI} \
    ${NANO_OPT} \
    --porec ${POREC} \
    --screen-human-contaminants

echo ${?}
