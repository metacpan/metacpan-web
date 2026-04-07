use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app );
use Test::More;

# Tests for MetaCPAN::Web::Controller base class methods.

app();

my $controller = MetaCPAN::Web->controller('Favorite');

subtest 'pageset caps total at 5000' => sub {
    my $pageset = $controller->pageset( 1, 100, 10_000 );
    is( $pageset->total_entries, 5000, 'total capped at 5000' );
};

done_testing;
