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
    my $release = $tx->find_value(
        '//div[@class="search-results"]//big[1]/strong/a/@href');
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
};

done_testing;
