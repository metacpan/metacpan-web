package MetaCPAN::Web::Controller::Account::Favorite;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

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

    my $user = $c->model('API::User')->get_profile( $c->token )->recv;

    my $faves_cv   = $c->model('API::Favorite')->by_user( $user->{user} );
    my $faves_data = $faves_cv->recv;
    my $faves      = [
        sort { $b->{date} cmp $a->{date} }
        map  { $_->{fields} } @{ $faves_data->{hits}{hits} }
    ];

    $c->stash( { faves => $faves } );

}

__PACKAGE__->meta->make_immutable;
