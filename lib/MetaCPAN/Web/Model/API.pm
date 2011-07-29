package MetaCPAN::Web::Model::API;

use Moose;
use namespace::autoclean;
extends 'Catalyst::Model::Adaptor';

__PACKAGE__->meta->make_immutable;

1;
