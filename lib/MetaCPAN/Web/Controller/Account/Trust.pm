package MetaCPAN::Web::Controller::Account::Trust;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub add : Local {
    my ( $self, $c ) = @_;
    $c->detach('/forbidden') unless ( $c->req->method eq 'POST' );
    my $model         = $c->model('API::User');
    my $trust_details = $c->req->params;
    my $res;
    if ( $trust_details->{remove} ) {
        $res = $model->remove_trust( $trust_details, $c->token )->recv;
    }
    else {
        $res = $model->add_trust( $trust_details, $c->token )->recv;
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

__PACKAGE__->meta->make_immutable;
