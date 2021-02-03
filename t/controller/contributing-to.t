use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi tx );

test_psgi app, sub {
    my $cb = shift;

    ok( my $res = $cb->( GET '/contributing-to/DOESNTEXIST' ),
        'GET /contributing-to/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET '/contributing-to/Moose' ),
        'GET /contributing-to/Moose' );
    is( $res->code, 200, 'code 200' );

    my $tx = tx($res);
    $tx->like(
        '/html/head/title',
        qr/Moose::Manual::Contributing/,
        'title includes Moose::Manual::Contributing'
    );
    ok(
        $tx->find_value(
            '//a[@href="/pod/distribution/Moose/lib/Moose/Manual/Contributing.pod"]'
        ),
        'contains permalink to Contributing doc'
    );

    ok(
        $res = $cb->(
            GET '/contributing-to/Acme-Test-MetaCPAN-NoContributingDoc'
        ),
        'GET /contributing-to/Acme-Test-MetaCPAN-NoContributingDoc'
    );
    is( $res->code, 404, 'code 404' );

    my $tx2 = tx($res);
    $tx2->find_value( '//div[contains(@class, "content")]',
        'page has content' );
    $tx2->like(
        '//div[@class="content about"]',
        qr/No Contributing guidelines.+found/,
        'content includes "No Contributing guidelines"'
    );
};

done_testing;
