use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;

    ok( my $res = $cb->( GET '/pod/DOESNTEXIST' ), 'GET /pod/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET '/pod/Moose' ), 'GET /pod/Moose' );
    is( $res->code, 200, 'code 200' );

    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose/, 'title includes Moose' );
    ok( $tx->find_value('//a[@href="/pod/Moose"]'),
        'contains permalink to resource' );

    ok(
        my $this = $tx->find_value(
            '//li[text()="Permalinks"]/following-sibling::li[a[text()="This version"]][1]/a[text()="This version"]/@href'
        ),
        'contains link to "this" version'
    );

    my $latest = $res->content;
    ok( $res = $cb->( GET $this ), "GET $this" );

    my $tx2 = tx($res);
    ok( $tx->find_value('//div[contains(@class, "content")]'),
        'page has content' );
    is(
        $tx2->find_value('//div[contains(@class, "content")]'),
        $tx->find_value('//div[contains(@class, "content")]'),
        'content of both urls is exactly the same'
    );

    # Request with lowercase author redirects to uppercase author.
    ( my $lc_this = $this )
        =~ s{(/pod/release/)([^/]+)}{$1\L$2};    # lc author name
    ok( $res = $cb->( GET $lc_this ), "GET $lc_this" );
    is( $res->code, 301, '301 on lowercase author name' );
    is( $res->headers->header('location'),
        $this, 'redirect to uppercase author name' );
};

done_testing;
