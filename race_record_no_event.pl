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
use Device::LSM303DLHC;
use Getopt::Long 'GetOptions';
use File::Spec;
use JSON::XS ();
use Time::HiRes ();

use lib 'lib';
use LocalGPSNMEA;

use constant DEBUG => 1;


my $GPS_DEV     = '/dev/ttyAMA0';
my $GPS_BAUD    = 9600;
my $FILE_DIR    = 'public';
my $RECORD_TIME = 0.1;
my $SWITCH_PIN  = 22;
my $LED_PIN     = 24;
GetOptions(
    'gps-dev=s'   => \$GPS_DEV,
    'record-to=s' => \$FILE_DIR,
);


{
    my $is_recording = 0;
    my ($rpi, $gps, $accel, $json);
    my ($vid_fh, $data_fh, $vid_in_fh);

    sub start_record
    {
        ($rpi, $gps, $accel, $json) = @_;

        my $time      = time();
        my $vid_file  = File::Spec->catfile( $FILE_DIR, 'record_' . $time
            . '.h264' );
        my $data_file = File::Spec->catfile( $FILE_DIR, 'record_' . $time
            . '.json' );
        say "Writing vid to $vid_file"   if DEBUG;
        say "Writing data to $data_file" if DEBUG;

        open( $vid_fh, '>', $vid_file ) or do {
            warn "Could not open '$vid_file': $!\n";
            return;
        };
        open( $data_fh, '>', $data_file ) or do {
            warn "Could not open '$data_file': $!\n";
            close $vid_fh;
            return;
        };

        print $data_fh "[\n" . $json->encode({
            start => [Time::HiRes::gettimeofday]
        })
            . "\n";
        $vid_in_fh = $rpi->vid_stream( 0, 'video/H264' );

        $rpi->output_pin( $LED_PIN, 1 );
        $is_recording = 1;
        return 1;
    }

    sub stop_record
    {
        close $vid_fh;
        close $vid_in_fh;

        print $data_fh "," . $json->encode({
            end => [ Time::HiRes::gettimeofday ]
        }) . "\n";
        print $data_fh "]";
        close $data_fh;

        $rpi->output_pin( $LED_PIN, 0 );
        $is_recording = 0;
        return 1;
    }

    sub do_recording_actions
    {
        return 1 unless $is_recording;

        ## Get and write telemetry data
        my ($ns, $lat, $ew, $lon) = $gps->get_position;
        my $velocity_kph = $gps->get_velocity;
        my $accl_reading = $accel->getAccelerationVectorInG;
        my $time = [Time::HiRes::gettimeofday];

        my $json_encoded = "," . $json->encode({
            gps     => {
                ns   => $ns,
                ew   => $ew,
                lat  => $lat,
                long => $lon,
                kph  => $velocity_kph,
            },
            accel   => $accl_reading,
            time    => $time,
        }) . "\n";
        print $data_fh $json_encoded;


        ## Get and write video
        #while( my $in_bytes = read( $vid_in_fh, my $buf, 1024 * 64 ) ) {
        #    print $vid_fh $buf;
        #}
    }
}


sub loop
{
    my ($rpi, $gps, $accel, $json) = @_;
    state $last_switch_setting = 0;
    state $is_now_recording    = 0;

    my $this_switch_setting = $rpi->input_pin( $SWITCH_PIN );
    if( $this_switch_setting && !$last_switch_setting ) {
        # Button was just pressed, so start or stop recording
        if( $is_now_recording ) {
            say "Stop recording" if DEBUG;
            eval { stop_record() };
            $is_now_recording = 0;
        }
        else {
            say "Start recording" if DEBUG;
            start_record( $rpi, $gps, $accel, $json );
            $is_now_recording = 1;
        }
    }

    do_recording_actions();
    $last_switch_setting = $this_switch_setting;
    return 1;
}


{
    my $rpi = Device::WebIO::RaspberryPi->new;

    my $gps = LocalGPSNMEA->new(
        Port => $GPS_DEV,
        Baud => $GPS_BAUD,
    );

    my $lsm = Device::LSM303DLHC->new(
        I2CBusDevicePath => '/dev/i2c-1',
    );
    my $accel = $lsm->Accelerometer;
    $accel->enable;

    my $json = JSON::XS->new;
    $json->pretty( 0 );

    $rpi->set_as_input( $SWITCH_PIN );
    $rpi->set_as_output( $LED_PIN );
    $rpi->output_pin( $LED_PIN, 0 );

    say "Ready" if DEBUG;
    while(1) {
        loop( $rpi, $gps, $accel, $json );
    }
}
