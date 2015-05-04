package Local::VideoOverlay::VelocityOutput;
use v5.14;
use warnings;
use Moose::Role;


sub draw_velocity
{
    my ($self, $args) = @_;
    my $width                   = $args->{width};
    my $height                  = $args->{height};
    my $img                     = $args->{img};
    my $position_width_percent  = $args->{position_width_percent};
    my $position_height_percent = $args->{position_height_percent};
    my $color                   = $args->{color};
    my $bg_color                = $args->{bg_color};
    my $kph                     = $args->{kph};
    my $convert_to_mph          = $args->{convert_to_mph};
    my $font                    = $args->{font};

    my $value = sprintf( '%.1f',
        $convert_to_mph ? $self->_kph_to_mph( $kph ) : $kph );
    my $units = $convert_to_mph ? 'mph' : 'km/h';
    my $str = $value . ' ' . $units;

    # TODO make font size proportional to width/height?
    my $font_size = 20;

    my $start_x = int( $width  * ($position_width_percent  / 100) );
    my $start_y = int( $height * ($position_height_percent / 100) );
    # Very rough estimate of size of the string in pixels
    my $end_x   = $start_x + (length($str) * ($font_size / 2));
    my $end_y   = $start_y + $font_size;

    $img->box(
        color  => $bg_color,
        filled => 1,
        xmin   => $start_x - 2,
        ymin   => $start_y - ($font_size - 2),
        xmax   => $end_x + 2,
        ymax   => $end_y - $font_size + 2,
    );
    $img->string(
        x      => $start_x,
        y      => $start_y,
        string => $str,
        font   => $font,
        size   => $font_size,
        color  => $color,
    );

    return 1;
}

sub _kph_to_mph
{
    my ($self, $kph) = @_;
    return $kph / 1.609344;
}

1;
__END__

