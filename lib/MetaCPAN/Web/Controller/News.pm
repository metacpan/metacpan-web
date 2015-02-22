package MetaCPAN::Web::Controller::News;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use Data::Dumper;
use Path::Tiny qw/path/;

sub news : Local : Path('/news') {
    my ( $self, $c ) = @_;

    my $file = $c->config->{home} . '/News.md';
    my $news = path($file)->slurp_utf8;
    $news =~ s|^Title:\s*(.*)|expand_title($1)|egm;

    $c->stash( template => 'news.html', news => $news );
}

sub expand_title {
    my ($title) = @_;

    my $a_name = $title;
    $a_name =~ s/\W+//g;

    return qq[<a name="$a_name" />$title];
}

1;
