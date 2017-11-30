use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

sub check_author {
    my ($tx) = @_;
    $tx->ok( '@itemscope', 'root node needs an itemscope' );
    $tx->is( '@itemtype', 'http://schema.org/Person',
        'author has correct type' );
    $tx->ok( './/a[@itemprop="url"]',     'author\'s URL found' );
    $tx->ok( './/span[@itemprop="name"]', 'author\'s name found' );
}

sub check_rating {
    my ($tx) = @_;
    $tx->ok( '@itemscope', 'root node needs an itemscope' );
    $tx->is(
        '@itemtype',
        'http://schema.org/AggregateRating',
        'rating has correct type'
    );
    $tx->ok( './/span[@itemprop="ratingValue"]', 'rating found' );
    $tx->ok( './/span[@itemprop="reviewCount"]', 'review count found' );
}

sub check_offer {
    my ($tx) = @_;
    $tx->ok( '@itemscope', 'root node needs an itemscope' );
    $tx->is( '@itemtype', 'http://schema.org/Offer',
        'offer has correct type' );
    $tx->is( './/span[@itemprop="price"]', '0', 'price is correct' );
}

sub check_application {
    my ($tx) = @_;
    $tx->ok( '@itemscope', 'root node needs an itemscope' );
    $tx->ok( './/span[@itemprop="name" and text()="DBI"]',
        'name found and correct' );
    $tx->ok( './/span[@itemprop="softwareVersion"]',
        'software version found' );
    $tx->ok( './/a[@itemprop="downloadUrl"]', 'download URL found' );
    $tx->ok( './/span[@itemprop="fileSize"]', 'file size found' );
    $tx->ok( './/a[@itemprop="url"]',         'URL found' );

    $tx->ok( './/span[@itemprop="author"]', \&check_author,
        'author node found' );
    $tx->ok( './/span[@itemprop="aggregateRating"]',
        \&check_rating, 'rating found' );
    $tx->ok( './/span[@itemprop="offers"]', \&check_offer, 'offers found' );
}

test_psgi app, sub {
    my $cb = shift;

    ok( my $res = $cb->( GET '/pod/DBI' ), 'GET a pod' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->ok( '//div[@itemtype="http://schema.org/SoftwareApplication"]',
        \&check_application, 'found SoftwareApplication' );

    ok( $res = $cb->( GET '/release/DBI' ), 'GET a release' );
    is( $res->code, 200, 'code 200' );
    $tx = tx($res);
    $tx->not_ok( '//*[@itemtype or @itemscope or @itemname]',
        'no schema.org attributes found' );

    ok( $res = $cb->( GET '/search?q=DBI' ), 'GET a search' );
    is( $res->code, 200, 'code 200' );
    $tx = tx($res);
    $tx->not_ok( '//*[@itemtype or @itemscope or @itemname]',
        'no schema.org attributes found' );

};

done_testing;
