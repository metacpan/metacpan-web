use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/release/DOESNTEXIST" ),
        'GET /release/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET "/release/AUTHORDOESNTEXIST/DOESNTEXIST" ),
        'GET /release/AUTHORDOESNTEXIST/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET "/release/PERLER/DOESNTEXIST" ),
        'GET /release/PERLER/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET "/release/Moose" ), 'GET /release/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose/, 'title includes Moose' );
    ok( $tx->find_value('//a[@href="/release/Moose"]'),
        'contains permalink to resource' );

    # Confirm that the headings in the content div are in the expected order.
    my @headings = ( 'Documentation', 'Modules', 'Provides', 'Examples', 'Other files' );
    my $heading  = 0;

    $tx->ok( '//div[@class="content"]/strong', sub {
        $_->is( '.', $headings[$heading], "heading $headings[$heading] in expected location");
        $heading++;
    } , 'headings in correct order');

    ok( my $this = $tx->find_value('//a[text()="This version"]/@href'),
        'contains link to "this" version' );
    my $latest = $tx->find_value('//div[@class="content"]');
    ok( $res = $cb->( GET $this ), "GET $this" );
    my $tx_latest = tx($res);
    is(
        $latest,
        $tx_latest->find_value('//div[@class="content"]'),
        'content of both urls is exactly the same'
    );

    # get module with lc author
    $this =~ s{(/release/.*?/)}{lc($1)}e; # lc author name
    ok( $res = $cb->( GET $this ), "GET $this" );
    is( $res->code, 301, 'code 301' );
};

done_testing;
