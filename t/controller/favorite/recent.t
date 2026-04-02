use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi tx );
use Test::More;

test_psgi app, sub {
    my $cb = shift;

    subtest 'recent favorites' => sub {
        ok( my $res = $cb->( GET '/favorite/recent' ),
            'GET /favorite/recent' );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);
        $tx->like(
            '/html/head/title',
            qr/Recent Favorites/,
            'title includes Recent Favorites'
        );
    };

    subtest 'recent favorites with pagination params' => sub {
        ok( my $res = $cb->( GET '/favorite/recent?p=2&size=10' ),
            'GET /favorite/recent?p=2&size=10' );
        is( $res->code, 200, 'code 200' );
    };
};

done_testing;
