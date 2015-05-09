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
use Test::More tests => 6;
use v5.14;
use Test::Differences::Color;
use lib 'lib';
use_ok( 'Local::VideoOverlay::Timeline' );

my $time = Local::VideoOverlay::Timeline->new;
$time->add({
    time  => [ 0, 30 ],
    accel => {
        x => 0.1,
        y => 0.2,
        z => 0.9,
    },
});
$time->add({
    time => [ 0, 60 ],
    gps  => {
        lat  => 10,
        long => 20,
        ns   => 'N',
        ew   => 'W',
        kph  => 1,
    },
});
$time->add({
    time  => [ 0, 33533 ],
    accel => {
        x => 0.2,
        y => 0.3,
        z => 0.8,
    },
});
$time->add({
    time => [ 0, 33533 ],
    gps  => {
        lat  => 15,
        long => 20,
        ns   => 'N',
        ew   => 'W',
        kph  => 1,
    },
});
$time->add({
    time  => [ 0, 66866 ],
    accel => {
        x => 0.2,
        y => 0.3,
        z => 0.9,
    },
});
$time->add({
    time => [ 0, 66867 ],
    gps  => {
        lat  => 15,
        long => 25,
        ns   => 'N',
        ew   => 'W',
        kph  => 1,
    },
});


my $iter = $time->get_iterator( [ 0, 200 ], [ 0, 100199 ], 1 / 30 );
eq_or_diff( $iter->(), {
    accel => {
        x => 0.2,
        y => 0.3,
        z => 0.8,
    },
    gps  => {
        lat  => 15,
        long => 20,
        ns   => 'N',
        ew   => 'W',
        kph  => 1,
    },
    time => [ 0, 200 ],
});
eq_or_diff( $iter->(), {
    accel => {
        x => 0.2,
        y => 0.3,
        z => 0.8,
    },
    gps  => {
        lat  => 15,
        long => 20,
        ns   => 'N',
        ew   => 'W',
        kph  => 1,
    },
    time => [ 0, 33533 ],
});
eq_or_diff( $iter->(), {
    accel => {
        x => 0.2,
        y => 0.3,
        z => 0.9,
    },
    gps  => {
        lat  => 15,
        long => 25,
        ns   => 'N',
        ew   => 'W',
        kph  => 1,
    },
    time => [ 0, 66866 ],
});
eq_or_diff( $iter->(), {
    accel => {
        x => 0.2,
        y => 0.3,
        z => 0.9,
    },
    gps  => {
        lat  => 15,
        long => 25,
        ns   => 'N',
        ew   => 'W',
        kph  => 1,
    },
    time => [ 0, 100199 ],
});
ok(! defined $iter->(), "End of timeline" );
