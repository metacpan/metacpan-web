package MetaCPAN::Web::View::JSON;

use Moose;

extends 'Catalyst::View::JSON';

# Catalyst::View::JSON is not a Moose.
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
