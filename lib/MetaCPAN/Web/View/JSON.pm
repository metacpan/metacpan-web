package MetaCPAN::Web::View::JSON;

use Moose;

# Catalyst::View::JSON uses JSON::MaybeXS
use Cpanel::JSON::XS ();    ## no perlimports

extends 'Catalyst::View::JSON';

__PACKAGE__->config( {
    expose_stash      => 'json',
    json_encoder_args => {
        canonical => 1,
    },
} );

# Catalyst::View::JSON is not a Moose.
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
