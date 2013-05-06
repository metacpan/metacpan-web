use strict;
use warnings;
use utf8;
use Test::More;
use MetaCPAN::Web::Test;
use Encode qw(encode is_utf8);

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/search" ),
        'GET /search' );
    is( $res->code, 302, 'code 302' );

    # Empty search query results in redirect.
    ok( $res = $cb->( GET "/search?q=" ), 'GET /search?q=' );
    is( $res->code, 302, 'code 302' );
    # Empty search query for lucky searches also redirects.
    ok( $res = $cb->( GET "/search?q=&lucky=1" ), 'GET /search?q=&lucky=1' );
    is( $res->code, 302, 'code 302' );

    ok( $res = $cb->( GET "/search?q=moose\">" ), 'GET /search?q=moose">' );
    is( $res->code, 200, 'code 200' );
    ok( $res->content =~ /0 results/, '0 results for an invalid search term' );

    ok( $res = $cb->( GET "/search?q=moose" ), 'GET /search?q=moose' );
    is( $res->code, 200, 'code 200' );

    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/moose/, 'title includes search term' );
    my $release = $tx->find_value(
        '//div[@class="search-results"]//div[1]/big[1]/strong/a/@href');
    ok( $release, "found release $release" );

    # Moose has ratings (other things on this search page likely do as well)
    $tx->like(
      '//div[@class="search-results"]//div[starts-with(@class, "rating-")]/following-sibling::a',
      qr/\d+ reviews?/i,
      'current rating and number of reviews listed'
    );

    ok( $res = $cb->( GET $release), "GET $release" );
    is( $res->code, 200, 'code 200' );

    # test search operators
    my $author = 'rjbs';
    $res = $cb->( GET "/search?q=author%3Arjbs+app" );
    is( $res->code, 200, 'search restricted by author OK' )
      or diag explain $res;

    $tx = tx($res);
    $tx->ok('//div[@class="search-results"]//div[@class="module-result"]/a[@class="author"]', sub {
      my $node = shift;
      $node->is('.', uc($author), 'dist owned by queried author')
        or diag explain $node;
    }, 'all dists owned by queried author');

    # as of 2013-01-20 there was only one page of results
    search_and_find_module($cb,
        "ねんねこ", # no idea what this means - rwstauner 2013-01-20
        'Lingua::JA::WordNet',
        'search for UTF-8 characters',
    );
};

done_testing;

sub req_200_ok {
    my ($cb, $req, $desc) = @_;
    ok( my $res = $cb->($req), $desc );
    is $res->code, 200, "200 OK";
    return $res;
}

sub search_and_find_module {
    my ($cb, $query, $exp_mod, $desc) = @_;
    $query = encode("UTF-8" => $query) if is_utf8($query);
    my $res = req_200_ok( $cb, GET("/search?q=$query"), $desc);
    my $tx = tx($res);
    $tx->is(
        qq!//div[\@class="search-results"]//div[\@class="module-result"]//a[\@href="/module/$exp_mod"]!,
        $exp_mod,
        "$desc: found expected module",
    );
}
