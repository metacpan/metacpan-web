use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi tx );
use Test::More;

test_psgi app, sub {
    my $cb = shift;

    subtest 'author favorites page' => sub {
        ok( my $res = $cb->( GET '/author/PERLER/favorites' ),
            'GET /author/PERLER/favorites' );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);
        $tx->like(
            '/html/head/title',
            qr/Favorites of PERLER/,
            'title includes author name'
        );
    };

    subtest 'author favorites with pagination params' => sub {
        ok( my $res = $cb->( GET '/author/PERLER/favorites?p=1&size=10' ),
            'GET /author/PERLER/favorites?p=1&size=10' );
        is( $res->code, 200, 'code 200' );
    };

    subtest 'unknown author returns 404' => sub {
        ok( my $res = $cb->( GET '/author/DOESNTEXIST/favorites' ),
            'GET /author/DOESNTEXIST/favorites' );
        is( $res->code, 404, 'code 404' );
    };

    subtest 'lowercase author redirects' => sub {
        ok( my $res = $cb->( GET '/author/perler/favorites' ),
            'GET /author/perler/favorites' );
        is( $res->code, 301, 'code 301' );
        is(
            $res->header('Location'),
            'http://localhost/author/PERLER/favorites',
            '301 target'
        );
    };
};

done_testing;
