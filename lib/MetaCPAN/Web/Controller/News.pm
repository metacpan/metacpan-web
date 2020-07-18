package MetaCPAN::Web::Controller::News;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use Path::Tiny qw( path );

sub news : Path : Args(0) {
    my ( $self, $c ) = @_;

    my $file = $c->config->{home} . '/News.md';
    my $news = path($file)->slurp_utf8;
    $news =~ s/^Title:\s*//gm;

    $c->stash( {
        news     => $news,
        template => 'news.tx',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
