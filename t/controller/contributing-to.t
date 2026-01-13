use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi tx );
use Test::More;

test_psgi app, sub {
    my $cb = shift;

    ok( my $res = $cb->( GET '/dist/DOESNTEXIST/contribute' ),
        'GET /dist/DOESNTEXIST/contribute' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET '/dist/Moose/contribute' ),
        'GET /dist/Moose/contribute' );
    is( $res->code, 200, 'code 200' );

    my $tx = tx($res);
    $tx->like(
        '/html/head/title',
        qr/Moose::Manual::Contributing/,
        'title includes Moose::Manual::Contributing'
    );
    ok(
        $tx->find_value(
            '//a[@href="/dist/Moose/view/lib/Moose/Manual/Contributing.pod"]'
        ),
        'contains permalink to Contributing doc'
    );

    ok(
        $res = $cb->(
            GET '/dist/Acme-Test-MetaCPAN-NoContributingDoc/contribute'
        ),
        'GET /dist/Acme-Test-MetaCPAN-NoContributingDoc/contribute'
    );
    is( $res->code, 404, 'code 404' );

    my $tx2 = tx($res);
    $tx2->find_value( '//main', 'page has content' );
    $tx2->like(
        q[//div[contains-token(@class, 'about')]],
        qr/No Contributing guidelines.+found/,
        'content includes "No Contributing guidelines"'
    );
};

done_testing;
