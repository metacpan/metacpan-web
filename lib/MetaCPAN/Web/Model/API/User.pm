package MetaCPAN::Web::Model::API::User;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, $token ) = @_;
    $self->request( "/user", undef, { token => $token } );
}

sub delete_identity {
    my ($self, $identity, $token) = @_;
    $self->request("/user/identity/$identity", undef, { method => 'DELETE', token => $token });
}

sub update_profile {
    my ($self, $data, $token) = @_;
    $self->request("/user/profile", $data, { method => 'PUT', token => $token });
}

sub get_profile {
    my ($self, $token) = @_;
    $self->request("/user/profile", undef, { token => $token });
}

1;
