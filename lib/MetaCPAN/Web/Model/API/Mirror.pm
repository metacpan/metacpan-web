package MetaCPAN::Web::Model::API::Mirror;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

sub search {
    my ( $self, $query ) = @_;
    $self->request( "/mirror/search", undef, { q => $query } );
}

__PACKAGE__->meta->make_immutable;

1;
