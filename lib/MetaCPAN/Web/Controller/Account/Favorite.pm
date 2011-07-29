package MetaCPAN::Web::Controller::Account::Favorite;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub add : Local {
    my ( $self, $c ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    my $model = $c->model('API')->user;
    my $data  = $c->req->params;
    if ( $data->{remove} ) {
        $model->remove_favorite( $data, $c->token )->recv;
    }
    else {
        $model->add_favorite( $data, $c->token )->recv;
    }
    if ( $c->req->looks_like_browser ) {
        $c->res->redirect( $c->req->referer );
    }
    else {
        $c->stash( { success => \1 } );
        $c->detach( $c->view('JSON') );
    }
}

__PACKAGE__->meta->make_immutable;
