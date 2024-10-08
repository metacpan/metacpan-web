use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi );
use Test::More;

test_psgi app, sub {
    my $cb = shift;
    {
        ok( my $res = $cb->( GET '/static/images/metacpan-logo.svg' ),
            'GET /static/images/logo.png...' );
        is( $res->code,                 200,   'code 200' );
        is( $res->header('Set-Cookie'), undef, 'No cookie' );
        is( $res->header('Surrogate-Control'),
            'max-age=31536000', 'Image Surrogate-Control as a year' );
    }
};

done_testing;
