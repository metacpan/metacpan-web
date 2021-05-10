package MetaCPAN::Web::Model::API::User;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

sub login {
    my ( $self, $auth ) = @_;
    return $self->request( '/oauth2/access_token', undef, $auth );
}

sub get {
    my ( $self, $token ) = @_;
    $self->request( '/user', undef, { access_token => $token } );
}

sub delete_identity {
    my ( $self, $token, $identity ) = @_;
    $self->request(
        "/user/identity/$identity", undef,
        { access_token => $token }, 'DELETE'
    );
}

sub update_profile {
    my ( $self, $token, $data ) = @_;
    $self->request( '/user/profile', $data,
        { access_token => $token }, 'PUT' );
}

sub get_profile {
    my ( $self, $token ) = @_;
    $self->request( '/user/profile', undef, { access_token => $token } );
}

sub add_favorite {
    my ( $self, $token, $data ) = @_;
    $self->request( '/user/favorite', $data, { access_token => $token } );
}

sub remove_favorite {
    my ( $self, $token, $data ) = @_;
    $self->request( '/user/favorite/' . $data->{distribution},
        undef, { access_token => $token }, 'DELETE' );
}

sub turing {
    my ( $self, $token, $answer ) = @_;
    $self->request(
        '/user/turing',
        { answer       => $answer },
        { access_token => $token },
    );
}

__PACKAGE__->meta->make_immutable;

1;
