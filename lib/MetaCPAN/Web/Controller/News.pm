package MetaCPAN::Web::Controller::News;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use Path::Tiny qw/path/;

sub news : Local : Path('/news') {
    my ( $self, $c ) = @_;

    my $file = $c->config->{home} . '/News.md';
    my $news = path($file)->slurp_utf8;
    $news =~ s/^Title:\s*//gm;

    $c->stash( template => 'news.html', news => $news );
}

__PACKAGE__->meta->make_immutable;

1;
