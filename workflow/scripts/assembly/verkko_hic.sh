#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

# verkko with Hi-C phasing.
# --hifi (HiFi / ONT-Duplex / HERRO-corrected) and Hi-C R1/R2 are required;
# ultra-long ONT via --nano is optional.

OUTPUT_DIR=$1
ONT=$2
HIFI=$3
HIC_READ1=$4
HIC_READ2=$5

# Treat empty string / "NA" / "-" as "input not provided".
present() { [ -n "${1:-}" ] && [ "${1}" != "NA" ] && [ "${1}" != "-" ]; }

if ! present "${HIFI}"; then
    echo "ERROR: --hifi input (HiFi / ONT-Duplex / HERRO-corrected) is required for verkko" >&2
    exit 1
fi
if ! present "${HIC_READ1}" || ! present "${HIC_READ2}"; then
    echo "ERROR: Hi-C R1 and R2 are required for verkko_hic" >&2
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
    --hic1 ${HIC_READ1} \
    --hic2 ${HIC_READ2} \
    --screen-human-contaminants

echo ${?}
