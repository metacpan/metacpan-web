use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/search" ),
        'GET /search' );
    is( $res->code, 302, 'code 302' );
    diag('invalid search term');
    ok( $res = $cb->( GET "/search?q=moose\">" ), 'GET /search?q=moose">' );
    is( $res->code, 200, 'code 200' );
    ok( $res->content =~ /0 results/, '0 results' );
    
    ok( $res = $cb->( GET "/search?q=moose" ), 'GET /search?q=moose' );
    is( $res->code, 200, 'code 200' );
    
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/moose/, 'title includes search term' );
    my $release = $tx->_findv(
        '//div[@class="search-results"]//big[1]/strong/a/@href');
    ok( $release, "found release $release" );

    ok( $res = $cb->( GET $release), "GET $release" );
    is( $res->code, 200, 'code 200' );
};

done_testing;
