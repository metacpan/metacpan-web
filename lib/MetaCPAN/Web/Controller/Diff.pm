package MetaCPAN::Web::Controller::Diff;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('diff') : Chained('/') : CaptureArgs(0) {
}

sub release : Local : Args(4) {
    my ( $self, $c, @path ) = @_;
    my $diff = $c->model('API::Diff')->releases(@path)->get;
    $c->stash( { diff => $diff, template => 'diff.html' } );
}

sub file : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $diff = $c->model('API::Diff')
        ->files( $c->req->params->{source}, $c->req->params->{target} )->get;
    $c->stash( { diff => $diff, template => 'diff.html' } );
}

__PACKAGE__->meta->make_immutable;

1;
