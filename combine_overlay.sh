#!/bin/bash
INPUT_VID=$1
OVERLAY_VID=$2
OUTPUT_VID=$3
DELAY=$4

ffmpeg -i ${INPUT_VID} -itsoffset ${DELAY} -i ${OVERLAY_VID} -filter_complex 'overlay=format=yuv420' -b:v 8000000 ${OUTPUT_VID}
