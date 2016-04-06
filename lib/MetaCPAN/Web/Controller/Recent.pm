package MetaCPAN::Web::Controller::Recent;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index : Path {
    my ( $self, $c ) = @_;
    my $req = $c->req;

    my $page_size = $req->get_page_size(100);

    my ($data)
        = $c->model('API::Release')
        ->recent( $req->page, $page_size, $req->params->{f} || 'l' )->recv;
    my $latest = [ map { $_->{fields} } @{ $data->{hits}->{hits} } ];
    if ( @$latest ) {
        $c->res->last_modified( $latest->[0]->{date} );
        for my $e ( @$latest ) {
            next unless ref $e eq 'HASH';
            for my $k ( keys %$e ) {
                $e->{$k} = $e->{$k}[0] if ref $e->{$k} eq 'ARRAY';
            }
        }
    }
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
