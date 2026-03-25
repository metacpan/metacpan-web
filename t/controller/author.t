use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi tx );
use Test::More;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/author/DOESNTEXIST' ),
        'GET /author/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET '/author/perler' ), 'GET /author/perler' );
    is( $res->code, 301, 'code 301' );
    is(
        $res->header('Location'),
        'http://localhost/author/PERLER',
        '301 target'
    );
    ok( $res = $cb->( GET '/author/PERLER' ), 'GET /author/PERLER' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/PERLER/, 'title includes author name' );
    my $release = $tx->find_value('//table[1]//tbody/tr[1]/td[2]//a/@href');
    ok( $release, 'found a release' );

    ok(
        $tx->find_value(
            '//table[@id="metacpan_author_favorites"]//tbody/tr[1]/td[1]//a/@href'
        ),
        'found a favorite'
    );

    ok( $res = $cb->( GET $release ), "GET $release" );
    is( $res->code, 200, 'code 200' );

    ok( $res = $cb->( GET '/author/DOESNTEXIST/releases' ),
        'GET /author/DOESNTEXIST/releases' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET '/author/perler/releases' ),
        'GET /author/perler/releases' );
    is( $res->code, 301, 'code 301' );
    is(
        $res->header('Location'),
        'http://localhost/author/PERLER/releases',
        '301 target'
    );
    ok( $res = $cb->( GET '/author/PERLER/releases' ),
        'GET /author/PERLER/releases' );
    is( $res->code, 200, 'code 200' );

    ok( $res = $cb->( GET '/author/DOESNTEXIST/latest' ),
        'GET /author/DOESNTEXIST/latest' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET '/author/perler/latest' ),
        'GET /author/perler/latest' );
    is( $res->code, 301, 'code 301' );
    is(
        $res->header('Location'),
        'http://localhost/author/PERLER/latest',
        '301 target'
    );
    ok( $res = $cb->( GET '/author/PERLER/latest' ),
        'GET /author/PERLER/latest' );
    is( $res->code, 200, 'code 200' );

    ok( $res = $cb->( GET '/author/DOESNTEXIST/favorites' ),
        'GET /author/DOESNTEXIST/favorites' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET '/author/perler/favorites' ),
        'GET /author/perler/favorites' );
    is( $res->code, 301, 'code 301' );
    is(
        $res->header('Location'),
        'http://localhost/author/PERLER/favorites',
        '301 target'
    );
    ok( $res = $cb->( GET '/author/PERLER/favorites' ),
        'GET /author/PERLER/favorites' );
    is( $res->code, 200, 'code 200' );
};

done_testing;
