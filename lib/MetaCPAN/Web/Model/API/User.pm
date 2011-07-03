package MetaCPAN::Web::Model::API::User;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, $msid ) = @_;
    $self->request( "/user", undef, { msid => $msid } );

}

1;
