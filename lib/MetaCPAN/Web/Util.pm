package MetaCPAN::Web::Util;

use strict;
use warnings;

use base 'Exporter';
our @EXPORT = qw(
    fix_structure
);

sub fix_structure {
    my $inp = shift || return;
    ref $inp eq 'HASH' or return $inp;
    my %ret = map {
        $_ => ( ref $inp->{$_}  eq 'ARRAY' ? $inp->{$_}[0] : $inp->{$_} )
    } keys %$inp;
    return \%ret;
}

1;
