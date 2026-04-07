package MetaCPAN::Web::Controller::Account::Favorite;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub add : Local : Args(0) {
    my ( $self, $c ) = @_;
    my $json = $c->req->accepts('application/json');
    $c->stash( { current_view => 'JSON' } )
        if $json;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    my $user = $c->user;
    $c->detach('/forbidden') unless $user;

    my $data = $c->req->params;
    my $res;
    if ( $data->{remove} ) {
        $res = $user->remove_favorite($data)->get;
    }
    else {
        $res = $user->add_favorite($data)->get;
    }

    if ($json) {
        if ( $res->{error} ) {
            $c->res->code(400);
            $c->stash->{json}{success} = \0;
            $c->stash->{json}{error}   = $res->{error};
        }
        else {
            $c->stash->{json}{success} = \1;
        }
    }
    else {
        $c->res->redirect( $c->req->referer );
    }
}

sub list : Local : Args(0) {
    my ( $self, $c ) = @_;

    my $page      = $c->req->page;
    my $page_size = $c->req->get_page_size(100);
    my $faves     = $self->faves( $c, $page, $page_size )->get;

    my $pageset = $self->pageset( $page, $page_size, $faves->{total} );

    $c->stash( {
        faves   => $faves->{favorites},
        took    => $faves->{took},
        pageset => $pageset,
    } );
}

sub list_as_json : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( { current_view => 'JSON' } );

    # This endpoint feeds the JS that renders favorite star icons on
    # every distribution page, so it needs all of a user's favorites
    # in a single request rather than a paginated slice.
    my $faves = $self->faves( $c, 1, 2_000 )->get;

    $c->stash->{json}{faves} = $faves->{favorites};

    $c->cdn_max_age('30d');

    # Make sure the user re-requests from Fastly each time
    $c->browser_never_cache(1);
}

sub faves {
    my ( $self, $c, $page, $size ) = @_;
    my $user = $c->user;
    return $c->model('API::Favorite')
        ->by_user( $user && $user->id, $page, $size );
}

__PACKAGE__->meta->make_immutable;

1;
