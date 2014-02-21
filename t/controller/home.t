use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/" ), "GET /" );
    is( $res->code, 200, 'code 200' );
};

done_testing;
