package MetaCPAN::Web::Model::API::User;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, $token ) = @_;
    $self->request( "/user", undef, { token => $token } );

}

1;
