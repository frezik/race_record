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
use Getopt::Long ();
use JSON::XS ();
use File::Temp ();
use lib 'lib';
use Local::VideoOverlay::Timeline;
use Local::VideoOverlay::FullOverlay;

my $ACCEL_JSON = '';
my $GPS_JSON   = '';
my $VID_JSON   = '';
Getopt::Long::GetOptions(
    'accel-json=s' => \$ACCEL_JSON,
    'gps-json=s'   => \$GPS_JSON,
    'vid-json=s'   => \$VID_JSON,
);
help() and exit(0) if !$ACCEL_JSON && !$GPS_JSON && !$VID_JSON;


sub help
{
    say "Usage: $0 --accel-json=<FILE> --gps-json=<FILE> --vid-json=<FILE>";
    return 1;
}

sub fill_timeline
{
    my ($timeline, $accel, $gps) = @_;

    my $add_to_timeline = sub {
        my ($data, $name) = @_;
        my @data = @$data;

        foreach (@data[ 1 .. ($#data-1)]) {
            my %timepoint = %$_;
            my $time = $timepoint{time};
            my $parsed_data = {
                map {
                    $_ eq 'time'
                        ? ()
                        : $timepoint{$_}
                } keys %timepoint,
            };

            say "Adding $name datapoint at timestamp $$time[0].$$time[1]";
            $timeline->add({
                time  => $time,
                $name => $parsed_data,
            });
        }
    };

    $add_to_timeline->( $accel, 'accel' );
    $add_to_timeline->( $gps,   'gps'   );
    return 1;
}

sub get_start_time
{
    my ($vid) = @_;
    return $vid->[0]{start};
}

sub create_overlay_pngs
{
    my ($tmp_dir, $timeline, $start_time) = @_;
    return 1;
}

sub decode_json_file
{
    my ($file) = @_;
    open( my $in, '<', $file ) or die "Can't open '$file': $!\n";
    my $got = '';
    while(read( $in, my $buf, 4096 ) ) {
        $got .= $buf;
    }
    close $in;

    my $data = JSON::XS::decode_json( $got );
    return $data;
}


{
    my $vid_json   = decode_json_file( $VID_JSON );
    my $gps_json   = decode_json_file( $GPS_JSON );
    my $accel_json = decode_json_file( $ACCEL_JSON );

    my $timeline = Local::VideoOverlay::Timeline->new;
    fill_timeline( $timeline, $accel_json, $gps_json );
    my $tmp_dir = File::Temp::tempdir( CLEANUP => 1 );
    my $start_time = get_start_time( $vid_json );
    say "Starting at $$start_time[0].$$start_time[1]";
    create_overlay_pngs( $tmp_dir, $timeline, $start_time );
}
