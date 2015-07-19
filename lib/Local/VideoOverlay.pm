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
package Local::VideoOverlay;
use v5.14;
use warnings;
use Moose::Role;
use MooseX::Types::Moose qw( Num Maybe );
use MooseX::Types::Structured qw( Tuple );
use Imager;


has width => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);
has height => (
    is       => 'ro',
    isa      => 'Int',
    required => 1,
);
has accel_x => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);
has accel_y => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);
has accel_z => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);
has max_accel_x => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);
has max_accel_y => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);
has max_accel_z => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);
has gps_lat => (
    is       => 'ro',
    isa      => Maybe[ Tuple[ Num, Num, Num ] ],
    required => 1,
);
has gps_lat_ns => (
    is       => 'ro',
    isa      => Moose::enum([qw{ n s N S }]),
    required => 1,
    default  => sub { 'n' },
);
has gps_long => (
    is       => 'ro',
    isa      => Maybe[ Tuple[ Num, Num, Num ] ],
    required => 1,
);
has gps_long_ew => (
    is       => 'ro',
    isa      => Moose::enum([qw{ e w E W }]),
    required => 1,
    default  => sub { 'w' },
);
has gps_kph => (
    is       => 'ro',
    isa      => 'Num',
    required => 1,
);


requires 'make_frame';


1;
__END__

