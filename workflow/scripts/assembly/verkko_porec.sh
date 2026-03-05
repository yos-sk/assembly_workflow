#!/bin/bash

set -xv
set -o errexit
set -o nounset
set -o pipefail

OUTPUT_DIR=$1
HIFI=$2
ONT=$3
POREC=$4

verkko \
    -d ${OUTPUT_DIR} \
    --hifi ${HIFI} \
    --nano ${ONT} \
    --porec ${POREC} \
    --screen-human-contaminants 
 
echo ${?}
