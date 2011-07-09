package MetaCPAN::Web::Controller::Account;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub logout : Local {
    my ($self, $c) = @_;
    $c->req->session->expire;
    $c->res->redirect('/');
}

sub settings : Local {
    my ($self, $c) = @_;
}

sub identities : Local {
    my ($self, $c) = @_;
}

1;
