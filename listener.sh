#!/bin/bash
PATH=/bin:/usr/bin:/usr/local/bin
SWITCH_PIN=22
LED_PIN=24
OUTPUT_DIR="public"

# Set pin input/output modes
gpio -g mode ${SWITCH_PIN} in
gpio -g mode ${LED_PIN} out
# Turn off LED
gpio -g write ${LED_PIN} 0


while [ true ]
do
    # Wait for switch to change state
    gpio -g wfi ${SWITCH_PIN} falling
    TIME=`date +%s`
    FILE_PREFIX="${OUTPUT_DIR}/record_${TIME}"

    # Launch data recording programs
    ./record_gps.pl --data-file="${FILE_PREFIX}_gps_data.json" &
    GPS_PID=$!
    ./record_accel.pl --data-file="${FILE_PREFIX}_accel_data.json" &
    ACCEL_PID=$!
    # This gives the GPS and accel recorders a chance to get going before 
    # we start the Big One
    sleep 2
    ./record_video.pl --vid-file="${FILE_PREFIX}.avi" --data-file="${FILE_PREFIX}_vid_data.json" &
    VID_PID=$!


    # Turn on LED
    gpio -g write ${LED_PIN} 1
    sleep 2


    # Wait for switch to change state
    gpio -g wfi ${SWITCH_PIN} falling
    # Kill data recording programs
    kill ${GPS_PID}
    kill ${ACCEL_PID}
    kill ${VID_PID}
    # Turn off LED
    gpio -g write ${LED_PIN} 0
    sleep 2
done
