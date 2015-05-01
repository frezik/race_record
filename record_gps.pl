#!/usr/bin/perl
use v5.14;
use warnings;
use Getopt::Long ();
use Time::HiRes ();
use lib 'lib';
use LocalJSONStream ();
use LocalGPSNMEA;

my $DATA_FILE = '';
my $PORT      = '/dev/ttyAMA0';
Getopt::Long::GetOptions(
    'data-file=s' => \$DATA_FILE,
    'port=s'      => \$PORT,
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


my $gps = LocalGPSNMEA->new(
    Port => $PORT,
    Baud => 9600,
);


while(1) {
    my ($ns,$lat,$ew,$lon) = $gps->get_position;
    my $velocity_kph       = $gps->get_velocity;
    $lat = correct_val( $lat );
    $lon = correct_val( $lon );

    print $out $json->output({
        time => [Time::HiRes::gettimeofday],
        ns   => $ns,
        ew   => $ew,
        lat  => $lat,
        long => $lon,
        kph  => $velocity_kph,
    });
}


sub correct_val
{
    my ($val) = @_;
    $val = int($val) + ($val - int($val)) * 1.66666667;
    return $val;
}
