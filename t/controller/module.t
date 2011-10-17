use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/module/DOESNTEXIST" ),
        'GET /module/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );
    ok( $res = $cb->( GET "/module/Moose" ), 'GET /module/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose/, 'title includes Moose' );
    ok( $tx->find_value('//a[@href="/module/Moose"]'),
        'contains permalink to resource'
    );
    ok( my $this = $tx->find_value('//a[text()="This version"]/@href'),
        'contains link to "this" version' );
    my $latest = $res->content;
    ok( $res = $cb->( GET $this ), "GET $this" );
    is($latest, $res->content, 'content of both urls is exactly the same');

};

done_testing;
