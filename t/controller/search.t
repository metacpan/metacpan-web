use strict;
use warnings;
use utf8;
use Test::More;
use MetaCPAN::Web::Test;
use Encode qw(encode is_utf8);

my %xpath = (
    search_results => 'div[contains(@class, "search-results")]',
    module_result  => 'div[@class="module-result"]',
);

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/search' ), 'GET /search' );
    is( $res->code, 302, 'code 302' );

    # Empty search query results in redirect.
    ok( $res = $cb->( GET '/search?q=' ), 'GET /search?q=' );
    is( $res->code, 302, 'code 302' );

    # Empty search query for lucky searches also redirects.
    ok( $res = $cb->( GET '/search?q=&lucky=1' ), 'GET /search?q=&lucky=1' );
    is( $res->code, 302, 'code 302' );

    ok( $res = $cb->( GET '/search?q=moose">' ), 'GET /search?q=moose">' );
    is( $res->code, 200, 'code 200' );
    ok( $res->content =~ /Task::Kensho/,
        'get recommendation about Task::Kensho on No result page' );

    ok( $res = $cb->( GET '/search?q=perlhacktips' ),
        'GET /search?q=perlhacktips' );
    is( $res->code, 200,
        'perlhacktips should be 200 not 302 because multiple files match' );

# TODO: Test something that has only one result but isn't indexed (/pod/X won't work).

    ok( $res = $cb->( GET '/search?q=moose' ), 'GET /search?q=moose' );
    is( $res->code, 200, 'code 200' );

    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/moose/, 'title includes search term' );
    my $release = $tx->find_value(
        qq!//$xpath{search_results}//div[1]/big[1]/strong/a/\@href!);
    ok( $release, "found release $release" );

    # Moose has ratings (other things on this search page likely do as well)
    $tx->like(
        qq!//$xpath{search_results}//a[\@href="http://cpanratings.perl.org/rate/?distribution=Moose"]/span/\@class!,
        qr/^rating-\d+$/i, 'ratings stars shown'
    );

    $tx->like(
        qq!//$xpath{search_results}//a[\@href="http://cpanratings.perl.org/dist/Moose"]!,
        qr/\d+ reviews?/i,
        'review number listed'
    );

    {
        my $description = $tx->find_value(
            qq!//$xpath{module_result}//p[\@class="description"][1]!);

        # This is very fragile.
        ok(
            $description =~ /Moose/
                && $description =~ /object/i
                && $description =~ /extension/,
            'got description for Moose'
        );
    }

    ok( $res = $cb->( GET $release), "GET $release" );
    is( $res->code, 200, 'code 200' );

    ok( $res = $cb->( GET '/search?q=RJBS&lucky=1' ),
        'GET /search?q=&lucky=1' );
    is( $res->headers->{location},
        '/author/RJBS', 'get redirect to author page' );

    ok( $res = $cb->( GET '/search?q=JSON&lucky=1' ),
        'GET /search?q=&lucky=1' );
    is( $res->headers->{location},
        '/pod/JSON', 'get redirect to pod page if module is found' );

    ok( $res = $cb->( GET '/search?q=win32&lucky=1' ),
        'GET /search?q=&lucky=1' );
    is( $res->headers->{location}, '/pod/Win32',
        'get redirect to pod page if module found and the query not upper case'
    );

    ok( $res = $cb->( GET '/search?q=WIN32&lucky=1' ),
        'GET /search?q=&lucky=1' );
    is( $res->headers->{location}, '/author/WIN32',
        'get redirect to author page when author is found and search with upper case'
    );

    # test search operators
    my $author = 'rjbs';
    $res = $cb->( GET '/search?q=author%3Arjbs+app' );
    is( $res->code, 200, 'search restricted by author OK' )
        or diag explain $res;

    $tx = tx($res);
    $tx->ok(
        qq!//$xpath{search_results}//$xpath{module_result}/a[\@class="author"]!,
        sub {
            my $node = shift;
            $node->is( q{.}, uc($author), 'dist owned by queried author' )
                or diag explain $node;
        },
        'all dists owned by queried author'
    );

    # as of 2013-01-20 there was only one page of results
    search_and_find_module(
        $cb,
        'ねんねこ',    # no idea what this means - rwstauner 2013-01-20
        'Lingua::JA::WordNet',
        'search for UTF-8 characters',
    );
};

done_testing;

sub req_200_ok {
    my ( $cb, $req, $desc ) = @_;
    ok( my $res = $cb->($req), $desc );
    is $res->code, 200, '200 OK';
    return $res;
}

sub search_and_find_module {
    my ( $cb, $query, $exp_mod, $desc ) = @_;
    $query = encode( 'UTF-8' => $query ) if is_utf8($query);
    my $res = req_200_ok( $cb, GET("/search?q=$query"), $desc );
    my $tx = tx($res);

    # make sure there is a link tag whose content is the module name
    $tx->ok(
        qq!grep(//$xpath{search_results}//$xpath{module_result}//a[1], "^\Q$exp_mod\E\$")!,
        "$desc: found expected module",
    );
}
