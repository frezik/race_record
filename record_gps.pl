#!/usr/bin/perl
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
use Device::GPS;
use Device::GPS::Connection::Serial;
use Getopt::Long ();
use Time::HiRes ();
use lib 'lib';
use LocalJSONStream ();

my $DATA_FILE = '';
my $PORT      = '/dev/ttyAMA0';
Getopt::Long::GetOptions(
    'data-file=s' => \$DATA_FILE,
    'port=s'      => \$PORT,
);
die "Need --data-file option\n" unless $DATA_FILE;

my $json = LocalJSONStream->new;
open( my $out, '>', $DATA_FILE ) or die "Can't open '$DATA_FILE': $!\n";
print $out $json->start;

$SIG{TERM} = $SIG{INT} = sub {
    print $out $json->end;
    close $out;
    exit 0;
};


my $gps = Device::GPS->new({
    connection => Device::GPS::Connection::Serial->new({
        port => $PORT,
        baud => 9600,
    }),
});
$gps->add_callback( $gps->CALLBACK_POSITION, sub {
    my ($time, $lat_deg, $lat_min, $lat_sec, $ns,
        $long_deg, $long_min, $long_sec, $ew,
        $quality, $satellites, $horz_dil, $altitude, $height, 
        $time_since_last_dgps, $dgps_station_id) = @_;
    print $out $json->output({
        time => [Time::HiRes::gettimeofday],
        ns   => $ns,
        ew   => $ew,
        lat  => [$lat_deg, $lat_min, $lat_sec],
        long => [$long_deg, $long_min, $long_sec],
    });
});
$gps->add_callback( $gps->CALLBACK_VELOCITY, sub {
    my ($true_track, undef, $mag_track, undef, $ground_speed_knots, undef,
        $ground_speed_kph, undef) = @_;
    print $out $json->output({
        time => [Time::HiRes::gettimeofday],
        kph  => $ground_speed_kph,
    });
});


while(1) { $gps->parse_next }
