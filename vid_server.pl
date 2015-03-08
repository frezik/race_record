#!perl
use v5.14;
use warnings;
use Mojolicious::Lite;

use constant VIDEO_DIR => '/home/tmurray/proj/race_record/public/';


get '/' => sub {
    my ($c) = @_;

    opendir( my $dir, VIDEO_DIR )
        or die "Can't open " . VIDEO_DIR . " for reading: $!\n";
    my @files = grep { -f (VIDEO_DIR . $_) } readdir $dir;
    closedir $dir;

    $c->render(
        template => 'dirlist',
        files    => \@files,
    );
};


app->start;
__DATA__

@@ dirlist.html.ep
<html>
<head>
<title>Video Listing</title>
</head>
<body>
<ul>
% foreach my $file (@$files) {
    <li><a href="/<%= $file %>"><%= $file %></a></li>
% }
</ul>
</body>
</html>
