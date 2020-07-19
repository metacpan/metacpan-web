package MetaCPAN::Web::Controller::Test;

use Moose;
use Cpanel::JSON::XS;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub _json_body {
    my ( $self, $c ) = @_;
    Cpanel::JSON::XS->new->utf8->decode(
        do { local $/; $c->req->body->getline }
    );
}

sub json_echo : Local {
    my ( $self, $c ) = @_;

    $c->stash->{json}{echo} = $self->_json_body($c);

    $c->detach( $c->view('JSON') );
}

__PACKAGE__->meta->make_immutable;

1;
