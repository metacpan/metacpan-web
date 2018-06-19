package MetaCPAN::Web::Controller::Authors;

use Moose;
use Data::Pageset;
use List::Util ();
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( {
        template => 'authors.html',
    } );
}

sub authors : Path : Args(1) {
    my ( $self, $c, $prefix ) = @_;

    if ( $prefix ne uc $prefix ) {
        $c->res->redirect(
            $c->uri_for( $c->action, [ uc $prefix ], $c->req->params ),
            301,    # Permanent
        );
        $c->detach;
    }

    my $page_size = $c->req->get_page_size(100);
    my $page = $c->req->page > 0 ? $c->req->page : 1;

    my $authors
        = $c->model('API::Author')->by_prefix( $prefix, $page_size, $page )
        ->get;

    $c->stash($authors);
    $c->stash( {
        page      => $page,
        page_size => $page_size,
        prefix    => $prefix,
    } );

    $c->forward('index');
}

__PACKAGE__->meta->make_immutable;

1;
