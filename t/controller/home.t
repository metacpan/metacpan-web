use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET q{/} ), 'GET /' );
    is( $res->code, 200, 'code 200' );
    test_cache_headers(
        $res,
        {
            cache_control     => 'max-age=3600',
            surrogate_key     => 'HOMEPAGE',
            surrogate_control => 'max-age=31556952',
        }
    );

};

done_testing;
