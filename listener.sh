#!/bin/bash
SWITCH_PIN=22
LED_PIN=24

gpio -g mode ${SWITCH_PIN} in
gpio -g mode ${LED_PIN} out


while [ true ]
do
    # Wait for switch to change state
    gpio -g wfi ${SWITCH_PIN} rising
    # Turn on LED
    gpio -g write ${LED_PIN} 1
    sleep 2

    # Wait for switch to change state
    gpio -g wfi ${SWITCH_PIN} rising
    # Turn off LED
    gpio -g write ${LED_PIN} 0
    sleep 2
done
