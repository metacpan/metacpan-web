package MetaCPAN::Web::Model::API::Distribution;
use Moose;
extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, $name ) = @_;
    $self->request("/distribution/$name");
}

__PACKAGE__->meta->make_immutable;

1;
