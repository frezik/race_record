#!perl
use v5.20;
use warnings;
use SVG;

require 'svg_creators.pl';
use lib './svg_creators';

use constant WIDTH_MM  => 85;
use constant HEIGHT_MM => 56;

use constant SCREW_HOLE_RADIUS_MM => (2.75 / 2);
use constant SCREW_HOLE_COORDS => [
    [ 3.5,            3.5            ],
    [ 58 + (3.5 / 2), 3.5            ],
    [ 3.5,            49 + (3.5 / 2) ],
    [ 58 + (3.5 / 2), 49 + (3.5 / 2) ],
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
    width  => WIDTH_MM,
    height => HEIGHT_MM,
);

# Draw screw holes
$draw->circle(
    cx => $_->[0],
    cy => $_->[1],
    r  => SCREW_HOLE_RADIUS_MM,
) for @{ +SCREW_HOLE_COORDS };


print $svg->xmlify;
