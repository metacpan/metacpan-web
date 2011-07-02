package MetaCPAN::Web::Controller::Login;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index :Path {
    my ( $self, $c ) = @_;
    my $code = $c->req->parameters->{code};
    return $c->detach('/not_found') unless ($code);
    my $data = $c->model('API')->request("/login/validate?code=$code")->recv;
    $c->req->session->set( msid => $data->{sid} );
    $c->res->redirect('/');
}

1;
