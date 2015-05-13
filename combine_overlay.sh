#!/bin/bash
INPUT_VID=$1
OVERLAY_VID=$2
OUTPUT_VID=$3

ffmpeg -i ${INPUT_VID} -i ${OVERLAY_VID} -filter_complex 'overlay=format=rgb' -b:v 8k ${OUTPUT_VID}
