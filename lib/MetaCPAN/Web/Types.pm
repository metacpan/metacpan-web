package MetaCPAN::Web::Types;

use strict;
use warnings;

# Added for the benefit of the prereq scanner
use MooseX::Types                  ();
use MooseX::Types::Common::Numeric ();
use MooseX::Types::Common::String  ();
use MooseX::Types::Moose;
use MooseX::Types::URI ();

use parent 'MooseX::Types::Combine';

__PACKAGE__->provide_types_from(
    qw(
        MooseX::Types::Common::Numeric
        MooseX::Types::Common::String
        MooseX::Types::Moose
        MooseX::Types::URI
        )
);

1;
