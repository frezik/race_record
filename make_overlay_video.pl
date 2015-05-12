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
use File::Copy ();
use Cwd ();
use lib 'lib';
use Local::VideoOverlay::Timeline;
use Local::VideoOverlay::FullOverlay;

my $ACCEL_JSON = '';
my $GPS_JSON   = '';
my $VID_JSON   = '';
my $OUTPUT     = '';
Getopt::Long::GetOptions(
    'accel-json=s' => \$ACCEL_JSON,
    'gps-json=s'   => \$GPS_JSON,
    'vid-json=s'   => \$VID_JSON,
    'output=s'     => \$OUTPUT,
);
help() and exit(0) if !$ACCEL_JSON && !$GPS_JSON && !$VID_JSON && !$OUTPUT;
help() and exit(0) if $OUTPUT !~ /\.mov\z/;


sub help
{
    say "Usage: $0 --accel-json=<FILE> --gps-json=<FILE> --vid-json=<FILE> -o <FILE>";
    say "";
    say "The file for -o must have .mov extension";
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
                        : ($_ => $timepoint{$_})
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

sub parse_vid_data
{
    my ($vid) = @_;
    my $start_time = $vid->[0]{start};
    my $width      = $vid->[1]{width};
    my $height     = $vid->[1]{height};
    my $fps        = $vid->[1]{fps};
    my $end_time   = $vid->[2]{end};
    return ($start_time, $end_time, $width, $height, $fps);
}

sub create_overlay_pngs
{
    my ($tmp_dir, $timeline, $start_time, $end_time, $fps, $width, $height) = @_;
    my $iter = $timeline->get_iterator( $start_time, $end_time, 1 / $fps );

    my $data = $iter->();
    # With 8 digits at 30fps, should be good for 925 hours of video
    my $frame_index = '00000000';
    while(defined $data) {
        my $time = $data->{time};
        say "Writing frame $frame_index at time $$time[0],$$time[1]";
        my $file = $tmp_dir . '/' . $frame_index . '.png';

        my $overlay = Local::VideoOverlay::FullOverlay->new({
            width       => $width,
            height      => $height,
            accel_x     => $data->{accel}{x},
            accel_y     => $data->{accel}{y},
            accel_z     => $data->{accel}{z},
            max_accel_x => 1.5,
            max_accel_y => 1.5,
            max_accel_z => 1.5,
            gps_lat     => $data->{gps}{lat},
            gps_long    => $data->{gps}{long},
            gps_lat_ns  => $data->{gps}{ns},
            gps_long_ew => $data->{gps}{ew},
            gps_kph     => $data->{gps}{kph},
        });
        my $img = $overlay->make_frame;
        $img->write(
            file => $file,
            type => 'png',
        );

        $data = $iter->();
        $frame_index = sprintf( '%08d', $frame_index + 1 );
    }
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

sub output_overlay_vid
{
    my ($tmp_dir, $output_file) = @_;
    my $cur_cwd = Cwd::getcwd();
    chdir $tmp_dir;

    my $cmd = join(' ', 'ffmpeg',
        '-i %08d.png',
        '-r 30',
        '-vcodec png',
        'overlay.mov',
    );
    (system( $cmd ) == 0)
        or die "Could not run system($cmd): $?";

    chdir $cur_cwd;
    File::Copy::move( $tmp_dir . '/overlay.mov', $output_file );
    
    return 1;
}


{
    my $vid_json   = decode_json_file( $VID_JSON );
    my $gps_json   = decode_json_file( $GPS_JSON );
    my $accel_json = decode_json_file( $ACCEL_JSON );

    my $timeline = Local::VideoOverlay::Timeline->new;
    fill_timeline( $timeline, $accel_json, $gps_json );
    my $tmp_dir = File::Temp::tempdir(
        CLEANUP => 1,
    );
    my ($start_time, $end_time, $width, $height, $fps)
        = parse_vid_data( $vid_json );
    say "Starting at $$start_time[0],$$start_time[1]";
    create_overlay_pngs( $tmp_dir, $timeline, $start_time, $end_time, $fps,
        $width, $height );
    say "All PNGs written to $tmp_dir";
    say "Creating video to $OUTPUT";
    output_overlay_vid( $tmp_dir, $OUTPUT );
    say "Done creating $OUTPUT";
}
