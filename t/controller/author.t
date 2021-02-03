use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi tx );

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
            '//table[@id="author_favorites"]//tbody/tr[1]/td[1]//a/@href'),
        'found a favorite'
    );

    ok( $res = $cb->( GET $release), "GET $release" );
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
};

done_testing;
