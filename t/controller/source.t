use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/module/Moose" ), 'GET /module/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    ok( my $source = $tx->_findv('//a[text()="Source"]/@href'),
        'contains link to Source' );
    ok( $res = $cb->( GET $source ), "GET $source" );
    ok( $res->code(200), 'code 200' );
    is( $res->header('Content-Type'),
        'text/html; charset=utf-8',
        'Content-type text/html; charset=utf-8'
    );
    ok( $res->content =~ /package Moose/, 'includes Moose package' );
};

done_testing;
