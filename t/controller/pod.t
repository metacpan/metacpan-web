use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/pod/DOESNTEXIST" ), 'GET /pod/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET "/pod/Moose" ), 'GET /pod/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose/, 'title includes Moose' );
    ok( $tx->find_value('//a[@href="/pod/Moose"]'),
        'contains permalink to resource' );

    ok( my $this = $tx->find_value('//li[text()="Permalinks"]/following-sibling::li[1]/a[text()="This version"]/@href'),
        'contains link to "this" version' );
    my $latest = $res->content;
    ok( $res = $cb->( GET $this ), "GET $this" );
    my $tx2 = tx($res);
    ok( $tx->find_value('//div[contains(@class, "content")]'),
        "page has content" );
    is(
        $tx2->find_value('//div[contains(@class, "content")]'),
        $tx->find_value('//div[contains(@class, "content")]'),
        'content of both urls is exactly the same'
    );

    like $tx->find_value('//div[contains(@class, "pod")]//pre/@class'),
        qr/^brush: pl; .+; metacpan-verbatim$/,
        'verbatim pre tag has syn-hi class';

    # Request with lowercase author redirects to uppercase author.
    $this =~ s{(/pod/release/)([^/]+)}{$1\L$2};    # lc author name
    ok( $res = $cb->( GET $this ), "GET $this" );
    is( $res->code, 301, 'code 301' );
};

done_testing;
