package MetaCPAN::Web::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils qw( extends );

BEGIN {
    extends qw(
        Types::Standard
        Types::Common::Numeric
        Types::Common::String
        Types::LoadableClass
        Types::URI
    );
}

__PACKAGE__->meta->add_coercion(
    name               => 'ArrayToHash',
    type_constraint    => Types::Standard::HashRef,
    coercion_generator => sub {
        my ( $coerce, $target, $key ) = @_;
        ArrayRef, => sprintf( q[+{ map { $_->{'%s'} => $_ } @$_ }], $key ),;
    },
);

1;
