package MetaCPAN::Web::Types;

use strict;
use warnings;

use Type::Library -base;
use Type::Utils -all;

BEGIN {
    extends qw(
        Types::Standard
        Types::Common::Numeric
        Types::Common::String
        Types::URI
    );
}

1;
