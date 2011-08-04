package MetaCPAN::Web::Controller::Diff;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('diff') : Chained('/') : CaptureArgs(0) {
}

sub diff_releases : Chained('index') : PathPart('release') : Args(4) {
    my ( $self, $c, @path ) = @_;
    my $diff = $c->model('API::Diff')->releases(@path)->recv;
    $c->stash(
        { diff => $diff, template => 'diff.html', type => 'release' } );
}

sub diff_files : Chained('index') : PathPart('file') : Args(0) {
    my ( $self, $c ) = @_;
    my $diff = $c->model('API::Diff')
        ->files( $c->req->params->{source}, $c->req->params->{target} )->recv;
    $c->stash( { diff => $diff, template => 'diff.html', type => 'source' } );
}

1;
