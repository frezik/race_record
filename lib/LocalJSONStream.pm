package LocalJSONStream;
use v5.14;
use warnings;
use JSON::XS;
use Time::HiRes ();


sub new
{
    my ($class) = @_;
    my $json = JSON::XS->new;
    $json->pretty(0);

    my $self = {
        json => $json,
    };

    bless $self => $class;
}

sub start
{
    my ($self) = @_;
    my $json = $self->{json};
    my $out = "[\n" . $json->encode({
        start => [Time::HiRes::gettimeofday],
    });
    return $out;
}

sub end
{
    my ($self) = @_;
    my $json = $self->{json};
    my $out = ',' . $json->encode({
        end => [Time::HiRes::gettimeofday],
    }) . "\n]";
    return $out;
}

sub output
{
    my ($self, $data) = @_;
    my $json = $self->{json};
    my $out = ',' . $json->encode( $data );
    return $out;
}


1;
__END__

