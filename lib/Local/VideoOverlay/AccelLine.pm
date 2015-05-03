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
    my $accel_percent_width           = $args->{accel_percent_width};
    my $accel_position_height_percent = $args->{accel_position_height_percent};
    my $accel_color                   = $args->{accel_color};
    my $bg_color                      = $args->{bg_color};
    my $img                           = $args->{img};

    my $center_x     = int( $width / 2 );
    my $line_size    = int( $width * ($accel_percent_width / 100) );
    my $line_start_x = $center_x - ($line_size / 2);
    my $line_end_x   = $line_start_x + $line_size;
    my $line_y       = int( $height * ($accel_position_height_percent / 100) );

    $img->box(
        color  => $bg_color,
        filled => 1,
        xmin   => $line_start_x - 2,
        # TODO height as a percentage of image size
        ymin   => $line_y - 9,
        xmax   => $line_end_x + 2,
        ymax   => $line_y + 2,
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

    my $line_half_width = $line_size / 2;
    # TODO calculate accel as a percentage of max accel
    my $indicator_x = $center_x + ($line_half_width * $accel_value);
    $img->line(
        color => $accel_color,
        x1    => $indicator_x,
        y1    => $line_y,
        x2    => $indicator_x,
        # TODO height as a percentage of image size
        y2    => $line_y - 7,
    );

    return 1;
}


1;
__END__

