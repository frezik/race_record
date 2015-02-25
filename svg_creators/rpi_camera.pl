#!perl
use v5.20;
use warnings;
use SVG;

use lib './svg_creators';
require 'svg_creators.pl';


use constant WIDTH_MM  => 25;
use constant HEIGHT_MM => 24;

use constant LENS_WIDTH_MM  => 8;
use constant LENS_HEIGHT_MM => 8;
use constant LENS_X_MM      => 8.5;
use constant LENS_Y_MM      => HEIGHT_MM - LENS_HEIGHT_MM - 5.5;

use constant SCREW_HOLE_RADIUS_MM => 1;
use constant SCREW_HOLE_COORDS => [
    [ 2,      2        ],
    [ 2 + 21, 2        ],
    [ 2,      2 + 12.5 ],
    [ 2 + 21, 2 + 12.5 ],
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

# Draw lens
$draw->rectangle(
    x      => mm_to_px( LENS_X_MM ),
    y      => mm_to_px( LENS_Y_MM ),
    width  => mm_to_px( LENS_WIDTH_MM ),
    height => mm_to_px( LENS_HEIGHT_MM ),
);

# Draw screw holes
$draw->circle(
    cx => mm_to_px( $_->[0] ),
    cy => mm_to_px( $_->[1] ),
    r  => mm_to_px( SCREW_HOLE_RADIUS_MM ),
) for @{ +SCREW_HOLE_COORDS };


print $svg->xmlify;
