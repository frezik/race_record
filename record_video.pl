#!/usr/bin/perl
use v5.14;
use warnings;
use Gtk2;
use Glib qw{ TRUE FALSE };
use GStreamer1;
use Getopt::Long ();
use lib 'lib';
use LocalJSONStream ();

my $DATA_FILE = '';
my $VID_FILE  = '';
my $WIDTH     = 1920;
my $HEIGHT    = 1080;
my $BITRATE   = 8000;
my $FPS       = 30;
my $AUDIO_DEV = 'hw:1,0';
Getopt::Long::GetOptions(
    'data-file=s' => \$DATA_FILE,
    'vid-file=s'  => \$VID_FILE,
    'width=i'     => \$WIDTH,
    'height=i'    => \$HEIGHT,
    'bitrate=i'   => \$BITRATE,
    'audio-dev=s' => \$AUDIO_DEV,
);
die "Need --data-file option\n" unless $DATA_FILE;
die "Need --vid-file option\n"  unless $VID_FILE;

$BITRATE *= 1024;


my $json = LocalJSONStream->new;
open( my $out, '>', $DATA_FILE ) or die "Can't open '$DATA_FILE': $!\n";

GStreamer1::init([ $0, @ARGV ]);
my $pipeline = GStreamer1::Pipeline->new( 'pipeline' );
$SIG{TERM} = $SIG{INT} = \&end;

my $loop = Glib::MainLoop->new;

my $rpi        = GStreamer1::ElementFactory::make( rpicamsrc => 'and_who' );
my $h264parse  = GStreamer1::ElementFactory::make( h264parse => 'are_you' );
my $capsfilter = GStreamer1::ElementFactory::make(
    capsfilter => 'the_proud_lord_said' );
my $sink    = GStreamer1::ElementFactory::make(
    filesink => 'that_i_should_bow_so_low' );
my $vid_queue = GStreamer1::ElementFactory::make( 'queue' => 'only_a_cat' );
my $muxer = GStreamer1::ElementFactory::make( 'avimux' => 'of_a_different_coat');
my $audio_src = GStreamer1::ElementFactory::make(
    'alsasrc' => 'the_only_truth_i_know' );
my $audio_caps = GStreamer1::ElementFactory::make(
    capsfilter => 'in_a_coat_of_red' );
my $mp3enc = GStreamer1::ElementFactory::make(
    lamemp3enc => 'or_a_coat_of_gold' );
my $audio_queue = GStreamer1::ElementFactory::make(
    queue => 'a_lion_still_has_claws' );

$rpi->set( bitrate => $BITRATE );
$audio_src->set( 'device' => $AUDIO_DEV );
$mp3enc->set( 'bitrate' => 256 );

my $caps = GStreamer1::Caps::Simple->new( 'video/x-h264',
    width  => 'Glib::Int' => $WIDTH,
    height => 'Glib::Int' => $HEIGHT,
    fps    => 'Glib::Int' => $FPS,
);
$capsfilter->set( caps => $caps );

my $caps_audio = GStreamer1::Caps::Simple->new( 'audio/x-raw',
    rate     => 'Glib::Int'    => 44100,
    channels => 'Glib::Int'    => 1,
    format   => 'Glib::String' => 'S16LE',
);
$audio_caps->set( caps => $caps_audio );

$sink->set( 'location' => $VID_FILE );


$pipeline->add( $muxer );

$pipeline->add( $_ ) for $audio_src, $audio_caps, $mp3enc, $audio_queue;
$audio_src->link(   $audio_caps  );
$audio_caps->link(  $mp3enc      );
$mp3enc->link(      $audio_queue );
$audio_queue->link( $muxer       );

$pipeline->add( $_ ) for $rpi, $h264parse, $capsfilter, $sink, $vid_queue;
$rpi->link( $h264parse );
$h264parse->link( $capsfilter );
$capsfilter->link( $vid_queue );
$vid_queue->link( $muxer );
$muxer->link( $sink );

my $bus = $pipeline->get_bus;
$bus->add_watch( \&bus_callback, $loop );

$pipeline->set_state( "playing" );
$loop->run;
$pipeline->set_state( "null" );
end();


sub bus_callback
{
    my ($bus, $msg, $loop) = @_;

    if( $msg->type & 'error' ) {
        warn $msg->error;
        $loop->quit;
    }
    elsif( $msg->type & 'eos' ) {
        $loop->quit;
    }
    elsif( $msg->type & 'stream-start' ) {
        warn "Started stream\n";
        print $out $json->start;
        print $out $json->output({
            width  => $WIDTH,
            height => $HEIGHT,
            fps    => $FPS,
        });
    }

    return TRUE;
}

sub end
{
    print $out $json->end;
    close $out;
    $pipeline->set_state( "null" );
    exit 0;
}
