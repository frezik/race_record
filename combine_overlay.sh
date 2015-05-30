#!/bin/bash
INPUT_VID=$1
OVERLAY_VID=$2
OUTPUT_VID=$3

ffmpeg -i ${INPUT_VID} -i ${OVERLAY_VID} -filter_complex 'overlay' -b:v 8000000 ${OUTPUT_VID}
