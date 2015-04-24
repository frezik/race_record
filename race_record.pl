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
use File::Spec 'catfile';
use AnyEvent;
use JSON::XS ();
use Time::HiRes ();

use lib 'lib';
use LocalGPSNMEA;

# Rpi Pins (physical, not GPIO)
# =============================
# 1     GPS PWR
# 2     Accelerometer PWR
# 3     Accelerometer SDA
# 4     Microphone PWR
# 5     Accelerometer SCL
# 6     Accelerometer GND
# 8     GPS RX
# 9     Microphone GND
# 10    GPS TX
# 14    GPS GND
# 15    Start/stop switch (GPIO 22)
# 17    Start/stop switch PWR
# 18    Start/stop light (GPIO 24)
# 20    Start/stop light GND
# 39    Mic cable ground
# 


my $GPS_DEV     = '/dev/ttyAMA0';
my $GPS_BAUD    = 9600;
my $FILE_DIR    = '/tmp';
my $RECORD_TIME = 0.1;
my $SWITCH_PIN  = 22;
my $LED_PIN     = 24;
GetOptions(
    'gps-dev=s'   => \$GPS_DEV,
    'record-to=s' => \$FILE_DIR,
);


{
    my ($vid_fh, $data_fh, $vid_in_fh, $vid_watcher, $data_log_watcher, $json,
        $rpi);
    sub start_record
    {
        my ($rpi_arg, $gps, $mag, $accel) = @_;
        my $rpi       = $rpi_arg;
        my $time      = time();
        my $vid_file  = catfile( $FILE_DIR, 'record_' . $time . '.h264' );
        my $data_file = catfile( $FILE_DIR, 'record_' . $time . '.json' );

        $json = JSON::XS->new;
        $json->pretty( 0 );

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
        my $byte_count = 0;
        $vid_watcher = AnyEvent->io(
            fh   => $vid_in_fh,
            poll => 'r',
            cb   => sub {
                my $in_bytes = read( $vid_in_fh, my $buf, 1024 * 64 );
                $byte_count += $in_bytes;

                my $writer; $writer = AnyEvent->io(
                    fh   => $vid_fh,
                    poll => 'w',
                    cb   => sub {
                        print $vid_fh $buf;
                        undef $writer;
                    },
                );
            },
        );

        $data_log_watcher = AnyEvent->timer(
            after    => 0.1,
            interval => $RECORD_TIME,
            cb       => sub {
                my ($ns, $lat, $ew, $lon) = $gps->get_position;
                my $velocity_kph = $gps->get_velocity;
                my $mag_reading = $mag->getMagnetometerScale1;
                my ($x, $y, $z, $wut) = $accel->getAccelerationVectorInG;
                my $time = [Time::HiRes::gettimeofday];

                my $json_encoded = "," . $json->encode({
                    gps     => {
                        ns   => $ns,
                        ew   => $ew,
                        lat  => $lat,
                        long => $lon,
                        kph  => $velocity_kph,
                    },
                    accel   => {
                        x   => $x,
                        y   => $y,
                        z   => $z,
                        wut => $wut
                    },
                    magneto => $mag_reading,
                    time    => $time,
                }) . "\n";

                my $writer; $writer = AnyEvent->io(
                    fh   => $data_fh,
                    poll => 'w',
                    cb   => sub {
                        print $data_fh $json_encoded;
                        undef $writer;
                    }
                );
            },
        );

        $rpi->output_pin( $LED_PIN, 1 );
    }

    sub stop_record
    {
        undef $vid_watcher;
        undef $data_log_watcher;
        close $vid_fh;
        close $vid_in_fh;

        print $data_fh "," . $json->encode({
            end => [ Time::HiRes::gettimeofday ]
        }) . "\n";
        print $data_fh "]";
        close $data_fh;

        $rpi->output_pin( $LED_PIN, 1 );
    }
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
    my $mag   = $lsm->Magnetometer;
    $_->enable for $accel, $mag;

    $rpi->set_as_input( $SWITCH_PIN );
    $rpi->set_as_output( $LED_PIN );
    $rpi->output_pin( $LED_PIN, 0 );

    # Keep track of toggle switch
    my $is_last_input_on = 0;
    my $is_now_recording = 0;
    my $input_pin_watcher; $input_pin_watcher = AnyEvent->timer(
        after    => 0.1,
        interval => 0.1,
        cb       => sub {
            my $input = $rpi->input_pin( $SWITCH_PIN );
            if( $input && !$is_last_input_on ) {
                # Button was just pressed, so start or stop recording
                if( $is_now_recording ) {
                    stop_record();
                    $is_now_recording = 0;
                }
                else {
                    start_record( $rpi, $gps, $mag, $accel );
                    $is_now_recording = 1;
                }
            }

            $is_last_input_on = $input;
            $input_pin_watcher;
        },
    );

    my $cv = AnyEvent->condvar;
    $cv->recv;
}
