use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_cache_headers test_psgi );
use Test::More;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/' ), 'GET /' );
    is( $res->code, 200, 'code 200' );
    test_cache_headers(
        $res,
        {
            cache_control => 'max-age=3600',
            surrogate_key =>
                'HOMEPAGE content_type=text/html content_type=text',
            surrogate_control =>
                'max-age=31556952, stale-while-revalidate=86400, stale-if-error=2592000',
        }
    );

};

done_testing;
