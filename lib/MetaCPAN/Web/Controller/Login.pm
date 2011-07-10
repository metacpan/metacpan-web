package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path {
    my ( $self, $c ) = @_;
    my $code = $c->req->parameters->{code};
    return $c->detach('/not_found') unless ($code);
    my $data
        = $c->model('API')
        ->request(
        "/oauth2/access_token?client_id=metacpan&client_secret=ClearAirTurbulence&code=$code"
        )->recv;
    $c->req->session->set( token => $data->{access_token} );
    $c->authenticate( { token => $data->{access_token} } );
    $c->res->redirect('/');
}

1;
