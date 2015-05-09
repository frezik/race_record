package Local::VideoOverlay::Timeline;
use v5.14;
use warnings;
use Moose;
use namespace::autoclean;
use Tie::Array::Sorted;

my $sort_sub = sub {
    my ($first_sec, $first_msec)   = @{ $_[0]->{time} };
    my ($second_sec, $second_msec) = @{ $_[1]->{time} };
    ($first_sec > $second_sec)   ? 1  :
    ($first_sec < $second_sec)   ? -1 :
    ($first_msec > $second_msec) ? 1  :
    ($first_msec < $second_msec) ? -1 : 0;
};

has '_timeline_accel' => (
    is      => 'ro',
    default => sub {
        my @array = ();
        tie @array, 'Tie::Array::Sorted', $sort_sub;
        \@array;
    },
);
has '_timeline_gps' => (
    is      => 'ro',
    default => sub {
        my @array = ();
        tie @array, 'Tie::Array::Sorted', $sort_sub;
        \@array;
    },
);


sub add
{
    my ($self, $data) = @_;
    push @{ $self->_timeline_accel }, $data if exists $data->{accel};
    push @{ $self->_timeline_gps   }, $data if exists $data->{gps};
    return 1;
}

sub get_iterator
{
    my ($self, $start_time, $end_time, $sec_per_frame) = @_;
    my ($start_sec, $start_msec) = (@$start_time);
    my $msec_per_frame = sprintf( '%.0f', 1_000_000 * $sec_per_frame );

    my @accel = @{ $self->_timeline_accel };
    my @gps   = @{ $self->_timeline_gps };
    my ($i_accel, $i_gps);

    # TODO Lots of redundancy here. Stop being redundant.
    my $i = 0;
    while((! defined $i_accel) && ($i <= $#accel)) {
        my ($sec, $msec) = @{ $accel[$i]{time} };
        if( ($sec > $start_sec) ||
            ($sec == $start_sec) && ($msec >= $start_msec) ) {
            $i_accel = $i;
        }
        $i++;
    }
    $i = 0;
    while((! defined $i_gps) && ($i <= $#gps)) {
        my ($sec, $msec) = @{ $gps[$i]{time} };
        if( ($sec > $start_sec) ||
            ($sec == $start_sec) && ($msec >= $start_msec) ) {
            $i_gps = $i;
        }
        $i++;
    }

    my $iter = sub {
        return undef
            if ($start_sec >= $end_time->[0]) && ($start_msec > $end_time->[1]);

        my $ret = {
            accel => $accel[$i_accel]{accel},
            gps   => $gps[$i_gps]{gps},
            time  => [ $start_sec, $start_msec ],
        };

        $start_msec += $msec_per_frame;
        if( $start_msec >= 1_000_000 ) {
            $start_sec  += sprintf( '%.0f', $start_msec / 1_000_000 );
            $start_msec %= 1_000_000;
        }

        my $i = $i_accel;
        my $found_accel = 0;
        while((! $found_accel) && ($i <= $#accel)) {
            my ($sec, $msec) = @{ $accel[$i]{time} };
            if( ($sec > $start_sec) ||
                ($sec == $start_sec) && ($msec >= $start_msec) ) {
                $i_accel = $i;
                $found_accel = 1;
            }
            $i++;
        }
        $i = $i_gps;
        my $found_gps = 0;
        while((! $found_gps) && ($i <= $#gps)) {
            my ($sec, $msec) = @{ $gps[$i]{time} };
            if( ($sec > $start_sec) ||
                ($sec == $start_sec) && ($msec >= $start_msec) ) {
                $i_gps = $i;
                $found_gps = 1;
            }
            $i++;
        }

        return $ret;
    };

    return $iter;
}


no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

