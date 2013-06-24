package MetaCPAN::Web::Model::API::Changes;
use Moose;
extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/changes/' . join( '/', @path ) );
}

1;
