#!/bin/bash
SWITCH_PIN=22
LED_PIN=24
OUTPUT_DIR="public/"

gpio -g mode ${SWITCH_PIN} in
gpio -g mode ${LED_PIN} out


while [ true ]
do
    # Wait for switch to change state
    gpio -g wfi ${SWITCH_PIN} falling
    TIME=`date +%s`
    FILE_PREFIX="${OUTPUT_DIR}/record_${TIME}"

    # Launch data recording programs
    #./record_video.pl --vid-file="${FILE_PREFIX}.avi" --data-file="${FILE_PREFIX}_vid_data.json" &
    #VID_PID=$!
    #./record_gps.pl --data-file="${FILE_PREFIX}_gps_data.json" &
    #GPS_PID=$!
    ./record_accel.pl --data-file="${FILE_PREFIX}_accel_data.json" &
    ACCEL_PID=$!

    # Turn on LED
    gpio -g write ${LED_PIN} 1
    sleep 2


    # Wait for switch to change state
    gpio -g wfi ${SWITCH_PIN} falling
    # Kill data recording programs
    #kill ${VID_PID}
    #kill ${GPS_PID}
    kill ${ACCEL_PID}
    # Turn off LED
    gpio -g write ${LED_PIN} 0
    sleep 2
done
