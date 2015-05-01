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
use EV ();
use AnyEvent;
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
my $WIDTH    = 1024;
my $HEIGHT   = 768;
my $BITRATE  = 2000;
my $TYPE     = 'avi';
GetOptions(
    'gps-dev=s'   => \$GPS_DEV,
    'record-to=s' => \$FILE_DIR,
    'width=i'     => \$WIDTH,
    'height=i'    => \$HEIGHT,
    'bitrate=i'   => \$BITRATE,
    'type=s'      => \$TYPE,
);

my %TYPE_LOOKUP = (
    avi  => 'video/x-msvideo',
    h264 => 'video/H264',
    #mp4  => 'video/mp4',
);
$TYPE = lc $TYPE;
die "Type '$TYPE' is not supported\n" if ! exists $TYPE_LOOKUP{$TYPE};
my $MIME_TYPE = $TYPE_LOOKUP{$TYPE};


{
    my ($vid_fh, $data_fh, $vid_in_fh, $data_log_watcher, $json, $rpi);
    sub start_record
    {
        my ($rpi_arg, $gps, $mag, $accel) = @_;
        $rpi          = $rpi_arg;
        my $time      = time();
        my $vid_file  = File::Spec->catfile( $FILE_DIR, 'record_' . $time
            . '.h264' );
        my $data_file = File::Spec->catfile( $FILE_DIR, 'record_' . $time
            . '.json' );
        say "Writing vid to $vid_file"   if DEBUG;
        say "Writing data to $data_file" if DEBUG;

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
        $rpi->vid_stream_callback( 0, $MIME_TYPE, sub {
            my ($frame) = @_;
            my $buf = pack( 'C*', @$frame );
            my $writer; $writer = AnyEvent->io(
                fh   => $vid_fh,
                poll => 'w',
                cb   => sub {
                    print $vid_fh $buf;
                    undef $writer;
                },
            );
            return 1;
        });

        $data_log_watcher = AnyEvent->timer(
            after    => 0.1,
            interval => $RECORD_TIME,
            cb       => sub {
                my ($ns, $lat, $ew, $lon) = $gps->get_position;
                my $velocity_kph = $gps->get_velocity;
                #my $mag_reading = $mag->getMagnetometerScale1;
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
                    #magneto => $mag_reading,
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
        my ($cv) = @_;
        $rpi->output_pin( $LED_PIN, 0 );

        undef $data_log_watcher;
        close $vid_fh;
        close $vid_in_fh;

        print $data_fh "," . $json->encode({
            end => [ Time::HiRes::gettimeofday ]
        }) . "\n";
        print $data_fh "]";
        close $data_fh;

        $cv->send;
    }
}


{
    my $cv = AnyEvent->condvar;
    my $rpi = Device::WebIO::RaspberryPi->new({
        vid_use_audio => 1,
        cv            => $cv,
    });

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

    $rpi->vid_set_width(  0, $WIDTH );
    $rpi->vid_set_height( 0, $HEIGHT );
    $rpi->vid_set_kbps(   0, $BITRATE );

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
                    say "Stop recording" if DEBUG;
                    eval { stop_record( $cv ) };
                    $is_now_recording = 0;
                }
                else {
                    say "Start recording" if DEBUG;
                    start_record( $rpi, $gps, $mag, $accel );
                    $is_now_recording = 1;
                }
            }

            $is_last_input_on = $input;
            $input_pin_watcher;
        },
    );

    say "Ready" if DEBUG;
    while( 1 ) {
        $cv->recv;
        $rpi->vid_stream_begin_loop( 0 );
    }
}
