use v5.20;
use warnings;

# According to SVG spec, there are 3.543307 pixels per mm.  See:
# http://www.w3.org/TR/SVG/coords.html#Units
use constant MM_IN_PX  => 3.543307;


sub mm_to_px
{
    my ($mm) = @_;
    return $mm * MM_IN_PX;
}


1;
