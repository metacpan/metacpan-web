package MetaCPAN::Web::Controller::Account::Favorite;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub auto : Private {
    my ( $self, $c ) = @_;

    # Needed to clear the cache
    my $user = $c->model('API::User')->get_profile( $c->token )->recv;
    $c->stash->{user} = $user;

    return 1;
}

sub add : Local {
    my ( $self, $c ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    my $model = $c->model('API::User');
    my $data  = $c->req->params;
    my $res;
    if ( $data->{remove} ) {
        $res = $model->remove_favorite( $data, $c->token )->recv;
    }
    else {
        $res = $model->add_favorite( $data, $c->token )->recv;
    }

    # Clear Fastly.. something changed
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

sub list : Local {
    my ( $self, $c ) = @_;
    $self->_add_fav_list_to_stash( $c, 1_000 );
}

sub list_as_json : Local {
    my ( $self, $c ) = @_;

    $self->_add_fav_list_to_stash( $c, 1_000 );

    my $user = $c->stash->{user};

    $c->add_surrogate_key( $self->_cache_key_for_user($c) );
    $c->cdn_cache_ttl( 86_400 * 30 );    # 30 days

    $c->detach( $c->view('JSON') );
}

sub _cache_key_for_user {
    my ( $self, $c ) = @_;

    my $user = $c->stash->{user};

    return 'user/' . $user->{user};
}

sub _add_fav_list_to_stash {
    my ( $self, $c, $size ) = @_;

    my $user = $c->stash->{user};

    my $faves_cv
        = $c->model('API::Favorite')->by_user( $user->{user}, $size );
    my $faves_data = $faves_cv->recv;
    my $faves      = [
        sort { $b->{date} cmp $a->{date} }
        map  { $_->{fields} } @{ $faves_data->{hits}{hits} }
    ];

    $c->stash( { faves => $faves } );

    return $user;

}

__PACKAGE__->meta->make_immutable;
