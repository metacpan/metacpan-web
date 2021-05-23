package MetaCPAN::Web::Controller::Account::Favorite;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub add : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( { current_view => 'JSON' } );
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

    # We need to purge if the rating has changes until the fav count
    # is moved from server to client side
    $c->purge_author_key( $data->{author} )     if $data->{author};
    $c->purge_dist_key( $data->{distribution} ) if $data->{distribution};

    if ( $c->req->looks_like_browser ) {
        $c->res->redirect(
              $res->{error}
            ? $c->req->referer
            : $c->uri_for('/account/turing/index')
        );
    }
    else {
        $c->res->code(400) if ( $res->{error} );
        $c->stash->{json}{success} = $res->{error} ? \0 : \1;
    }
}

sub list : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( { faves => $self->faves( $c, 1_000 )->get } );
}

sub list_as_json : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( { current_view => 'JSON' } );

    $c->stash->{json}{faves} = $self->faves( $c, 1_000 )->get;

    $c->cdn_max_age('30d');

    # Make sure the user re-requests from Fastly each time
    $c->browser_never_cache(1);
}

sub faves {
    my ( $self, $c, $size ) = @_;
    my $user = $c->user;
    return $c->model('API::Favorite')->by_user( $user && $user->id, $size );
}

__PACKAGE__->meta->make_immutable;

1;
