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
package LocalGPSNMEA;
use v5.14;
use warnings;
use base 'GPS::NMEA';


# Written idiomatically with the other GPS::NMEA methods
sub get_velocity
{
    my $self = shift;

    until ($self->parse eq 'GPVTG') {
        1;
    }

    my $d = $self->{NMEADATA};
    $d->{velocity_kph};
}


# Parses the VTG (Velocity) string into its components
#
# $GPVTG,<1>,<2>,<3>,<4>,<5>,<6>,<7>,<8>
# 1) True track
# 2) "T" (?)
# 3) Magnetic track
# 4) "M" (?)
# 5) Ground speed, knots
# 6) "N" (?)
# 7) Ground speed, km/s
# 8) "K"
#
sub GPVTG
{
    my $self = shift;
    $self->{NMEADATA} = {} unless ref($self->{NMEADATA});
    my $d = $self->{NMEADATA};

    (undef,
        $d->{true_track},
        $d->{true_track_identifier},
        $d->{mag_track},
        $d->{mag_track_identifier},
        $d->{velocity_knots},
        $d->{velocity_knots_identifier},
        $d->{velocity_kph},
        $d->{velocity_kph_identifier},
    ) = split( ',', shift );
    1;
}


1;
__END__

