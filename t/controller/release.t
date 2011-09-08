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

    $tx->like(
        '//select[@name="release"]/option[@value][1]',
        qr/\(\d{4}-\d{2}-\d{2}\)$/,
        'version ends with date in common format'
    );

    # Moose has ratings, but not all dists do (so be careful what we're testing with)
    $tx->like(
      '//div[@class="search-bar"]//div[starts-with(@class, "rating-")]/following-sibling::a',
      qr/\d+ reviews?/i,
      'current rating and number of reviews listed'
    );
    # all dists should get a link to rate
    $tx->like(
      '//div[@class="search-bar"]//a[contains(@href, "cpanratings")]',
      qr/Rate this/i,
      'cpanratings link to rate this dist'
    );

};

done_testing;
