#!perl
# Copyright (c) 2015  Timm Murray
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without 
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright notice, 
#       this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright 
#       notice, this list of conditions and the following disclaimer in the 
#       documentation and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
# POSSIBILITY OF SUCH DAMAGE.
use v5.14;
use warnings;
use Device::WebIO;
use Device::WebIO::RaspberryPi;
use GPS::NMEA;
use Device::LSM303DLHC;

# TODO
# * Start/stop logging when button pressed
#     * Light up LED to show recording
# * Video
# * GPS
# * 3-axis accelerometer
# * Web interface for viewing pics/video
# * Case for everything

# Rpi Pins (physical, not GPIO)
# =============================
# 1     GPS PWR
# 2     Accelerometer PWR
# 3     Accelerometer SDA
# 5     Accelerometer SCL
# 6     Accelerometer GND
# 8     GPS RX
# 10    GPS TX
# 14    GPS GND
# 15    Start/stop switch
# 17    Start/stop switch PWR
# 18    Start/stop light
# 20    Start/stop light GND
# 
my $rpi = Device::WebIO::RaspberryPi->new;
