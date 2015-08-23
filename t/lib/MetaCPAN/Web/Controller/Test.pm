package MetaCPAN::Web::Controller::Test;

use Moose;
BEGIN { extends 'MetaCPAN::Web::Controller' }

sub _json_body {
    my ( $self, $c ) = @_;
    JSON::MaybeXS->new->utf8->decode(
        do { local $/; $c->req->body->getline }
    );
}

sub json_echo : Local {
    my ( $self, $c ) = @_;

    $c->stash->{echo} = $self->_json_body($c);

    $c->detach( $c->view('JSON') );
}

__PACKAGE__->meta->make_immutable;

1;
