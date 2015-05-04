package Local::VideoOverlay::AccelLine;
use v5.14;
use warnings;
use Moose::Role;


sub draw_accel
{
    my ($self, $args) = @_;
    my $width                         = $args->{width};
    my $height                        = $args->{height};
    my $accel_value                   = $args->{accel_value};
    my $max_accel_value               = $args->{max_accel_value};
    my $accel_percent_width           = $args->{accel_percent_width};
    my $accel_position_height_percent = $args->{accel_position_height_percent};
    my $accel_color                   = $args->{accel_color};
    my $accel_indicator_color         = $args->{accel_indicator_color};
    my $bg_color                      = $args->{bg_color};
    my $img                           = $args->{img};
    my $font                          = $args->{font};

    my $center_x     = int( $width / 2 );
    my $line_size    = int( $width * ($accel_percent_width / 100) );
    my $line_start_x = $center_x - ($line_size / 2);
    my $line_end_x   = $line_start_x + $line_size;
    my $line_y       = int( $height * ($accel_position_height_percent / 100) );

    my $font_size = 15;

    $img->box(
        color  => $bg_color,
        filled => 1,
        xmin   => $line_start_x - $font_size - 2,
        # TODO height as a percentage of image size
        ymin   => $line_y - 9,
        xmax   => $line_end_x + $font_size + 2,
        ymax   => $line_y + $font_size + 9,
    );
    $img->box(
        color  => $accel_color,
        filled => 1,
        xmin   => $line_start_x,
        # TODO thickness (height) as a percentage of image size
        ymin   => $line_y - 1,
        xmax   => $line_end_x,
        ymax   => $line_y + 1,
    );

    # Draw scale lines
    $self->_draw_accel_indicator_line( $img, $line_size, $max_accel_value,
        $max_accel_value, $accel_color, $line_y, $center_x,
        1, $font, $font_size, $accel_color);
    $self->_draw_accel_indicator_line( $img, $line_size, 0,
        $max_accel_value, $accel_color, $line_y, $center_x,
        1, $font, $font_size, $accel_color);
    $self->_draw_accel_indicator_line( $img, $line_size, -$max_accel_value,
        $max_accel_value, $accel_color, $line_y, $center_x,
        1, $font, $font_size, $accel_color);

    $self->_draw_accel_indicator_line( $img, $line_size, $accel_value,
        $max_accel_value, $accel_indicator_color, $line_y, $center_x, 0);

    return 1;
}

sub _draw_accel_indicator_line
{
    my ($self, $img, $line_size, $accel_value, $max_accel_value, $accel_color,
        $line_y, $center_x, $write_value_str, $font, $font_size, $font_color)= @_;

    my $line_half_width = $line_size / 2;
    my $accel_fraction = $accel_value / $max_accel_value;
    my $indicator_x = $center_x + ($line_half_width * $accel_fraction);
    $img->line(
        color => $accel_color,
        x1    => $indicator_x,
        y1    => $line_y + 7,
        x2    => $indicator_x,
        # TODO height as a percentage of image size
        y2    => $line_y - 7,
    );

    if( $write_value_str ) {
        $img->align_string(
            x      => $indicator_x,
            y      => $line_y + $font_size + 2,
            string => $accel_value . 'g',
            font   => $font,
            size   => $font_size,
            color  => $font_color,
            halign => 'center',
            valign => 'bottom',
        );
    }

    return 1;
}


1;
__END__

