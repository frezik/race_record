#!perl
use v5.20;
use warnings;
use SVG;

require 'svg_creators.pl';
use lib './svg_creators';

use constant WIDTH_MM  => 9.525;
use constant HEIGHT_MM => 9.525;


my $svg = SVG->new(
    width  => mm_to_px( WIDTH_MM ),
    height => mm_to_px( HEIGHT_MM ),
);

my $draw = $svg->group(
    id    => 'draw',
    style => {
        stroke         => 'black',
        'stroke-width' => 0.1,
        fill           => 'none',
    },
);
$draw->circle(
    cx => (WIDTH_MM / 2),
    cy => (WIDTH_MM / 2),
    r  => mm_to_px( WIDTH_MM / 2 ),
);

print $svg->xmlify;
