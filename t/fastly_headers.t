use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    {
        ok( my $res = $cb->( GET '/static/images/logo.png' ),
            'GET /static/images/logo.png...' );
        is( $res->code,                 200,   'code 200' );
        is( $res->header('Set-Cookie'), undef, 'No cookie' );
        is( $res->header('Surrogate-Control'),
            'max-age=3600', 'Image Surrogate-Control' );
    }
};

done_testing;
