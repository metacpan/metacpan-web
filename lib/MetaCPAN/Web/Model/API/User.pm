package MetaCPAN::Web::Model::API::User;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, $token ) = @_;
    $self->request( "/user", undef, { token => $token } );
}

sub delete_identity {
    my ( $self, $identity, $token ) = @_;
    $self->request( "/user/identity/$identity", undef,
        { method => 'DELETE', token => $token } );
}

sub update_profile {
    my ( $self, $data, $token ) = @_;
    $self->request( "/user/profile", $data,
        { method => 'PUT', token => $token } );
}

sub get_profile {
    my ( $self, $token ) = @_;
    $self->request( "/user/profile", undef, { token => $token } );
}

sub add_favorite {
    my ( $self, $data, $token ) = @_;
    $self->request( "/user/favorite", $data, { token => $token } );
}

sub remove_favorite {
    my ( $self, $data, $token ) = @_;
    $self->request( "/user/favorite/" . $data->{distribution},
        undef, { method => 'DELETE', token => $token } );
}

sub add_trust {
    my ( $self, $data, $token ) = @_;
    $self->request( '/user/trust/', $data, { token => $token } );
}

sub remove_trust {
    my ( $self, $data, $token ) = @_;
    $self->request( '/user/trust/' . $data->{author},
        undef, { method => 'DELETE', token => $token } );
}

sub turing {
    my ( $self, $challenge, $answer, $token ) = @_;
    $self->request(
        "/user/turing",
        { challenge => $challenge, answer => $answer },
        { token     => $token }
    );
}

1;
