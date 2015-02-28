#!perl
use v5.20;
use warnings;
use SVG;

require 'svg_creators.pl';
use lib './svg_creators';

use constant WIDTH_MM  => 23;
use constant HEIGHT_MM => 21;

use constant SCREW_HOLE_RADIUS_MM => 1;
use constant SCREW_HOLE_COORDS    => [
    [ 2.5,            3 ],
    [ WIDTH_MM - 2.5, 3 ],
];



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

# Draw outline
$draw->rectangle(
    x      => 0,
    y      => 0,
    width  => mm_to_px( WIDTH_MM ),
    height => mm_to_px( HEIGHT_MM ),
);

# Draw screw holes
$draw->circle(
    cx => mm_to_px( $_->[0] ),
    cy => mm_to_px( $_->[1] ),
    r  => mm_to_px( SCREW_HOLE_RADIUS_MM ),
) for @{ +SCREW_HOLE_COORDS };


print $svg->xmlify;
