use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi );
use Test::More;

test_psgi app, sub {
    my $cb = shift;

    ok( my $res = $cb->( GET '/lab/dashboard' ), 'GET /lab/dashboard' );
    is( $res->code, 200, 'code 200' );
};

done_testing();
