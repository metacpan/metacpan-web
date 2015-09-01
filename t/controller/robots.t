use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET q{/robots.txt} ), 'GET /robots.txt' );
    is( $res->code, 200, 'code 200' );

SKIP: {
        skip 'Root controller is not serving /robots.txt!', 3;
        test_cache_headers(
            $res,
            {
                cache_control     => 'max-age=3600',
                surrogate_key     => 'ROBOTS',
                surrogate_control => 'max-age=86400',
            }
        );
    }
};

done_testing;
