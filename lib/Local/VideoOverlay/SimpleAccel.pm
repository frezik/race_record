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
package Local::VideoOverlay::SimpleAccel;
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;

with 'Local::VideoOverlay';

use constant DEBUG => 1;

use constant ACCEL_PERCENT_WIDTH           => 22;
use constant ACCEL_POSITION_HEIGHT_PERCENT => 90;
use constant ACCEL_COLOR_R                 => 237;
use constant ACCEL_COLOR_B                 => 31;
use constant ACCEL_COLOR_G                 => 141;
use constant OVERLAY_BACKGROUND_COLOR_R    => 216;
use constant OVERLAY_BACKGROUND_COLOR_G    => 216;
use constant OVERLAY_BACKGROUND_COLOR_B    => 199;


sub make_frame
{
    my ($self)  = @_;
    my $width   = $self->width;
    my $height  = $self->height;
    my $accel_x = $self->accel_x;
    my $img     = $self->_init_img( $width, $height );

    my $center_x     = int( $width / 2 );
    my $line_size    = int( $width * (ACCEL_PERCENT_WIDTH / 100) );
    my $line_start_x = $center_x - ($line_size / 2);
    my $line_end_x   = $line_start_x + $line_size;
    my $line_y       = int( $height * (ACCEL_POSITION_HEIGHT_PERCENT / 100) );
    say "Drawing at ($line_start_x, $line_y) to ($line_end_x, $line_y)" if DEBUG;

    my $overlay_background_color = Imager::Color->new(
        OVERLAY_BACKGROUND_COLOR_R, OVERLAY_BACKGROUND_COLOR_G,
        OVERLAY_BACKGROUND_COLOR_B, 0xFF );
    $img->box(
        color  => $overlay_background_color,
        filled => 1,
        xmin   => $line_start_x - 2,
        ymin   => $line_y - 9,
        xmax   => $line_end_x + 2,
        ymax   => $line_y + 2,
    );
    my $accel_color = Imager::Color->new(
        ACCEL_COLOR_R, ACCEL_COLOR_G, ACCEL_COLOR_B, 0xFF );
    $img->box(
        color  => $accel_color,
        filled => 1,
        xmin   => $line_start_x,
        ymin   => $line_y - 1,
        xmax   => $line_end_x,
        ymax   => $line_y + 1,
    );

    my $line_half_width = $line_size / 2;
    my $indicator_x = $center_x + ($line_half_width * $accel_x);
    say "Drawing indicator at ($indicator_x, $line_y)" if DEBUG;
    $img->line(
        color => $accel_color,
        x1    => $indicator_x,
        y1    => $line_y,
        x2    => $indicator_x,
        y2    => $line_y - 7,
    );

    return $img;
}

sub _init_img
{
    my ($self, $width, $height) = @_;

    my $img = Imager->new(
        xsize    => $width,
        ysize    => $height,
        channels => 4,
    ) or die Imager->errstr;

    my $transparent = Imager::Color->new( 0xFF, 0xFF, 0xFF, 0 );
    $img->flood_fill( x => 1, y => 1, color => $transparent );

    return $img;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

