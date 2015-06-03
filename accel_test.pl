#!/usr/bin/perl
use v5.14;
use warnings;
use Device::LSM303DLHC;
use Time::HiRes ();
use Getopt::Long ();
use lib 'lib';
use LocalJSONStream ();

my $dev   = Device::LSM303DLHC->new({
    I2CBusDevicePath => '/dev/i2c-1',
});
my $accel = $dev->Accelerometer;
$accel->enable;


while(1) {
    my $accel = $accel->getAccelerationVectorInG;
    say "X: " . $accel->{x} .
        " Y: " . $accel->{y} . 
        " Z: " . $accel->{z};
}
