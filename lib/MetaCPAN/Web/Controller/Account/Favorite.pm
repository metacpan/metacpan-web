package MetaCPAN::Web::Controller::Account::Favorite;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub add : Local : Args(0) {
    my ( $self, $c ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    my $model = $c->model('API::User');
    my $data  = $c->req->params;
    my $res;
    if ( $data->{remove} ) {
        $res = $model->remove_favorite( $data, $c->token )->get;
    }
    else {
        $res = $model->add_favorite( $data, $c->token )->get;
    }

    # We need to purge if the rating has changes until the fav count
    # is moved from server to client side
    $c->purge_author_key( $data->{author} )     if $data->{author};
    $c->purge_dist_key( $data->{distribution} ) if $data->{distribution};

    $c->purge_surrogate_key( $self->_cache_key_for_user($c) );

    if ( $c->req->looks_like_browser ) {
        $c->res->redirect(
              $res->{error}
            ? $c->req->referer
            : $c->uri_for('/account/turing/index')
        );
    }
    else {
        $c->stash( { success => $res->{error} ? \0 : \1 } );
        $c->res->code(400) if ( $res->{error} );
        $c->detach( $c->view('JSON') );
    }
}

sub list : Local : Args(0) {
    my ( $self, $c ) = @_;
    $self->_add_fav_list_to_stash( $c, 1_000 );
}

sub list_as_json : Local : Args(0) {
    my ( $self, $c ) = @_;

    $self->_add_fav_list_to_stash( $c, 1_000 );

    $c->add_surrogate_key( $self->_cache_key_for_user($c) );
    $c->cdn_max_age('30d');

    # Make sure the user re-requests from Fastly each time
    $c->browser_never_cache(1);

    $c->detach( $c->view('JSON') );
}

sub _cache_key_for_user {
    my ( $self, $c ) = @_;

    my $user = $c->user;

    return 'user/' . $user->id;
}

sub _add_fav_list_to_stash {
    my ( $self, $c, $size ) = @_;
    my $user  = $c->user;
    my $faves = $c->model('API::Favorite')->by_user( $user->id, $size )->get;
    $c->stash( { faves => $faves } );
    return $user;
}

__PACKAGE__->meta->make_immutable;

1;
