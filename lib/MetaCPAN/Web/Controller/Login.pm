package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;
    if ( my $code = $c->req->parameters->{code} ) {
        my $data
            = $c->model('API')
            ->request( "/oauth2/access_token?client_id="
                . $c->config->{consumer_key}
                . "&client_secret="
                . $c->config->{consumer_secret}
                . "&code=$code" )->recv;
        $c->req->session->set( token => $data->{access_token} );
        $c->authenticate( { token => $data->{access_token} } );
        $c->res->redirect('/');
    }
    else {
        $c->stash( { template => 'account/login.html' } );
    }
}

1;
