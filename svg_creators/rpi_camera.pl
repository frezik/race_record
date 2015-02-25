#!perl
use v5.20;
use SVG;

# According to SVG spec, there are 3.543307 pixels per mm.  See:
# http://www.w3.org/TR/SVG/coords.html#Units
use constant MM_IN_PX  => 3.543307;
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


sub mm_to_px
{
    my ($mm) = @_;
    return $mm * MM_IN_PX;
}



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

# Draw lens
$draw->rectangle(
    x      => LENS_X_MM,
    y      => LENS_Y_MM,
    width  => LENS_WIDTH_MM,
    height => LENS_HEIGHT_MM,
);

# Draw screw holes
$draw->circle(
    cx => $_->[0],
    cy => $_->[1],
    r  => SCREW_HOLE_RADIUS_MM,
) for @{ +SCREW_HOLE_COORDS };


print $svg->xmlify;
