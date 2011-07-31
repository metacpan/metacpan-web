package MetaCPAN::Web::API::User;

use Moose;
use namespace::autoclean;
with qw(MetaCPAN::Web::API::Request);

has api => (
    is       => 'ro',
    isa      => 'MetaCPAN::Web::API',
    weak_ref => 1,
);

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

__PACKAGE__->meta->make_immutable;

1;
