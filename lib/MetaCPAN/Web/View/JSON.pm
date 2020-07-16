package MetaCPAN::Web::View::JSON;

use Moose;
use Cpanel::JSON::XS ();

extends 'Catalyst::View::JSON';

__PACKAGE__->config( {
    expose_stash => 'json',
} );

sub encode_json {
    my ( $self, undef, $data ) = @_;
    Cpanel::JSON::XS->new->utf8->encode($data);
}

# Catalyst::View::JSON is not a Moose.
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
