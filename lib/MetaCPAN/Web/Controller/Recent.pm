package MetaCPAN::Web::Controller::Recent;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

use MetaCPAN::Web::Types qw( PositiveInt );

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $page_size = $req->param('size');
    unless ( is_PositiveInt($page_size) && $page_size <= 500 ) {
        $page_size = 100;
    }

    my ($data)
        = $c->model('API::Release')
        ->recent( $c->req->page, $page_size, $c->req->params->{f} || 'l' )
        ->recv;
    my $latest = [ map { $_->{fields} } @{ $data->{hits}->{hits} } ];
    $c->res->last_modified( $latest->[0]->{date} ) if (@$latest);
    $c->stash(
        {
            recent    => $latest,
            took      => $data->{took},
            total     => $data->{hits}->{total},
            template  => 'recent.html',
            page_size => $page_size,
        }
    );
}

sub log : Local {
    my ( $self, $c ) = @_;
    $c->stash( { template => 'recent/log.html' } );
}

sub faves : Path('/recent/favorites') {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/favorite/recent', 301 );
    $c->detach;
}

1;
