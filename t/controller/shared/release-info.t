use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    my $dist = 'Moose';

    foreach my $controller ( qw(module release) ) {
        my $req_uri = "/$controller/$dist";
        ok( my $res = $cb->( GET $req_uri ), "GET $req_uri" );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);

        $tx->like( '/html/head/title', qr/$dist/, qq["title includes name "$dist"] );

        ok( $tx->find_value(qq<//a[\@href="/$controller/$dist"]>),
            'contains permalink to resource'
        );

        ok( my $this = $tx->find_value('//a[text()="This version"]/@href'),
            'contains link to "this" version' );

        my $latest = $res->content;
        ok( $res = $cb->( GET $this ), "GET $this" );
        is($latest, $res->content, 'content of both urls is exactly the same');

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
    }
};

done_testing;
