package MetaCPAN::Web::Controller::Recent;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index : Path {
    my ( $self, $c ) = @_;
    my ($data) = $c->model('API::Release')->recent( $c->req->page, $c->req->params->{f} || 'l' )->recv;
    my $latest = [ map { $_->{_source} } @{ $data->{hits}->{hits} } ];
    $c->stash(
        {   recent   => $latest,
            took     => $data->{took},
            total    => $data->{hits}->{total},
            template => 'recent.html'
        }
    );
}

sub faves : Path('/recent/favorites') {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/favorite/recent', 301 );
    $c->detach;
}

1;
