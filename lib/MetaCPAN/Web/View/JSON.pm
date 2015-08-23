package MetaCPAN::Web::View::JSON;

use Moose;
use JSON::MaybeXS ();

extends 'Catalyst::View::JSON';

sub encode_json {
    my ( $self, $c, $data ) = @_;
    JSON::MaybeXS->new->utf8->encode($data);
}

# Catalyst::View::JSON is not a Moose.
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );

1;
