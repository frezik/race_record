#!/usr/bin/perl
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
