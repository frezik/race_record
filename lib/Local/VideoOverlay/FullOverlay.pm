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
package Local::VideoOverlay::FullOverlay;
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;

with 'Local::VideoOverlay';
with 'Local::VideoOverlay::AccelLine';
with 'Local::VideoOverlay::VelocityOutput';

use constant FONT_FILE                        => 'typeone.ttf';
use constant ACCEL_PERCENT_WIDTH              => 22;
use constant ACCEL_POSITION_HEIGHT_PERCENT    => 90;
use constant VELOCITY_POSITION_WIDTH_PERCENT  => 80;
use constant VELOCITY_POSITION_HEIGHT_PERCENT => 80;
# Colors from:
# http://colorschemedesigner.com/csd-3.5/#3C11Tw0w0w0w0
use constant BASE_COLOR_R                 => 0x0E;
use constant BASE_COLOR_G                 => 0x53;
use constant BASE_COLOR_B                 => 0xA7;
use constant BASE_INDICATOR_COLOR_R       => 0x68;
use constant BASE_INDICATOR_COLOR_G       => 0x99;
use constant BASE_INDICATOR_COLOR_B       => 0xD3;
use constant OVERLAY_BACKGROUND_COLOR_R    => 216;
use constant OVERLAY_BACKGROUND_COLOR_G    => 216;
use constant OVERLAY_BACKGROUND_COLOR_B    => 199;


sub make_frame
{
    my ($self)  = @_;
    my $width       = $self->width;
    my $height      = $self->height;
    my $img         = $self->_init_img( $width, $height );

    my $font = Imager::Font->new( file => FONT_FILE );

    my $base_color = Imager::Color->new( BASE_COLOR_R, BASE_COLOR_G,
        BASE_COLOR_B, 255 );
    my $base_indicator_color = Imager::Color->new( BASE_INDICATOR_COLOR_R,
        BASE_INDICATOR_COLOR_G, BASE_INDICATOR_COLOR_B, 255 );
    my $bg_color    = Imager::Color->new( OVERLAY_BACKGROUND_COLOR_R,
        OVERLAY_BACKGROUND_COLOR_G, OVERLAY_BACKGROUND_COLOR_B, 127 );
    $self->draw_accel({
        width                         => $width,
        height                        => $height,
        accel_value                   => $self->accel_x,
        max_accel_value               => $self->max_accel_x,
        accel_percent_width           => ACCEL_PERCENT_WIDTH,
        accel_position_height_percent => ACCEL_POSITION_HEIGHT_PERCENT,
        accel_color                   => $base_color,
        accel_indicator_color         => $base_indicator_color,
        bg_color                      => $bg_color,
        img                           => $img,
        font                          => $font,
    });
    $self->draw_velocity({
        width                   => $width,
        height                  => $height,
        img                     => $img,
        position_width_percent  => VELOCITY_POSITION_WIDTH_PERCENT,
        position_height_percent => VELOCITY_POSITION_HEIGHT_PERCENT,
        color                   => $base_color,
        bg_color                => $bg_color,
        kph                     => $self->gps_kph,
        convert_to_mph          => 1,
        font                    => $font,
    });

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

