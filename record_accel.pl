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
use Device::LSM303DLHC;
use Time::HiRes ();
use Getopt::Long ();
use lib 'lib';
use LocalJSONStream ();

my $DATA_FILE = '';
Getopt::Long::GetOptions(
    'data-file=s' => \$DATA_FILE,
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


my $dev   = Device::LSM303DLHC->new({
    I2CBusDevicePath => '/dev/i2c-1',
});
my $accel = $dev->Accelerometer;
$accel->enable;


while(1) {
    my $accel = $accel->getAccelerationVectorInG;
    print $out $json->output({
        time => [Time::HiRes::gettimeofday],
        %$accel,
    });
}
