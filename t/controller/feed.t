use strict;
use warnings;

use MetaCPAN::Web                   ();
use MetaCPAN::Web::Controller::Feed ();
use MetaCPAN::Web::Test qw(
    app
    GET
    override_api_response
    test_cache_headers
    test_psgi
    tx
);
use Test::More;
use Test::Warnings ();
use Try::Tiny qw( catch try );

sub get_feed_ok {
    my ( $cb, $test, $extra ) = @_;
    subtest $test => sub {
        ok( my $res = $cb->( GET $test), $test );
        is( $res->code, 200, 'code 200' );
        is(
            $res->header('content-type'),
            'application/rss+xml; charset=UTF-8',
            'Content-type is application/rss+xml'
        );

        my $tx = valid_xml( $res, $test );
        $extra->( $res, $tx ) if $extra;
    };
}

test_psgi app, sub {
    my $cb = shift;

    get_feed_ok(
        $cb,
        '/recent.rss',
        sub {
            my ( $res, $tx ) = @_;
            test_cache_headers(
                $res,
                {
                    cache_control => 'max-age=60',
                    surrogate_key =>
                        'RECENT DIST_UPDATES content_type=application/rss+xml content_type=application',
                    surrogate_control =>
                        'max-age=31556952, stale-if-error=2592000',
                }
            );
        }

    );
    get_feed_ok(
        $cb,
        '/author/PERLER/activity.rss',
        sub {
            my ( $res, $tx ) = @_;
            $tx->ok(
                q!grep(//item/description, "PERLER \+\+ed (\S+) from ([A-Z]+)")!,
                'found favorites in author feed',
            );
            $tx->ok(
                q!grep(//item/title, "PERLER has released (.+)")!,
                'found releases in author feed',
            );
            test_cache_headers(
                $res,
                {
                    cache_control => 'max-age=3600',
                    surrogate_key =>
                        'author=PERLER content_type=application/rss+xml content_type=application',
                    surrogate_control =>
                        'max-age=31556952, stale-if-error=2592000',
                }
            );
        }
    );
    get_feed_ok(
        $cb,
        '/dist/Moose/releases.rss',
        sub {
            my ( $res, $tx ) = @_;
            test_cache_headers(
                $res,
                {
                    cache_control => 'max-age=3600',
                    surrogate_key =>
                        'dist=MOOSE content_type=application/rss+xml content_type=application',
                    surrogate_control =>
                        'max-age=31556952, stale-if-error=2592000',
                }
            );
        }
    );
    get_feed_ok(
        $cb,
        '/news.rss',
        sub {
            my ( $res, $tx ) = @_;
            test_cache_headers(
                $res,
                {
                    cache_control => 'max-age=3600',
                    surrogate_key =>
                        'NEWS content_type=application/rss+xml content_type=application',
                    surrogate_control =>
                        'max-age=3600, stale-if-error=2592000',
                }
            );
        }
    );

    test_redirect( $cb, 'oalders' );

    subtest 'author 404' => sub {
        my $res = $cb->( GET '/author/XXX343WI^^^/activity.rss' );
        is( $res->code, 404, '404 when author does not exist' );
    };
};

sub test_redirect {
    my ( $cb, $author ) = @_;
    ok( my $redir = $cb->( GET "/author/\L$author\E/activity.rss" ),
        'lc author feed' );
    is( $redir->code, 301, 'permanent redirect' );

    # Ignore scheme and host, just check that uri path is what we expect.
    like(
        $redir->header('location'),
        qr{^(\w+://[^/]+)?/author/\U$author\E/activity\.rss},
        'redirect to uc feed'
    );

    $author = uc($author);

    test_cache_headers(
        $redir,
        {
            cache_control     => 'max-age=31556952',
            surrogate_key     => "content_type=text/html content_type=text",
            surrogate_control => 'max-age=31556952, stale-if-error=2592000',
        }
    );

}

sub valid_xml {
    my ($res) = @_;
    my ( $tx, $err );

    try { $tx = tx( $res, { feed => 1 } ) } catch { $err = $_[0] };

    ok( $tx, 'valid xml' );
    is( $err, undef, 'no errors' )
        or diag Test::More::explain $res;

    return $tx;
}

my $feed = MetaCPAN::Web::Controller::Feed->new( MetaCPAN::Web->new );

subtest 'get correct author favorite data format' => sub {
    my $favorite_data = [ {
        author       => 'DOLMEN',
        date         => '2013-07-05T14:41:26.000Z',
        distribution => 'Git-Sub',
    } ];

    my $entry
        = $feed->_format_favorite_entries( 'PERLHACKER', $favorite_data );
    is(
        $entry->[0]->{abstract},
        'PERLHACKER ++ed Git-Sub from DOLMEN',
        'get correct release abstract'
    );
    is( $entry->[0]->{link}, 'release/Git-Sub', 'get correct release link' );
    is(
        $entry->[0]->{name},
        'PERLHACKER ++ed Git-Sub',
        'get correct release title'
    );
    is( $entry->[0]->{author}, 'PERLHACKER', 'get correct author name' );
};

subtest 'get correct author release data format' => sub {
    my $data = [ {
        abstract     => 'Easy OO access to the FreshBooks.com API',
        author       => 'OALDERS',
        date         => '2014-05-03T03:06:44.000Z',
        distribution => 'Net-FreshBooks-API',
        name         => 'Net-FreshBooks-API-0.24',
        status       => 'latest',
    } ];

    my $entry = $feed->_format_release_entries($data);
    is(
        $entry->[0]->{abstract},
        'Easy OO access to the FreshBooks.com API',
        'get correct release abstract'
    );
    is(
        $entry->[0]->{link},
        'release/OALDERS/Net-FreshBooks-API-0.24',
        'get correct release link'
    );
    is(
        $entry->[0]->{name},
        'OALDERS has released Net-FreshBooks-API-0.24',
        'get correct release title'
    );
    is( $entry->[0]->{author}, 'OALDERS', 'get correct author name' );
};

# do this last so the override_api_response only affects this
my $how_many = 0;
override_api_response(
    if => sub { !$how_many++ },    # fail only once
    sub { Future->fail("Error"); },
);
test_psgi app, sub {
    my $cb = shift;
    subtest 'retry on transient failure' => sub {
        ok( my $res = $cb->( GET '/recent.rss' ) );
        is( $res->code, 200, 'code 200' );
        is(
            $res->header('content-type'),
            'application/rss+xml; charset=UTF-8',
            'Content-type is application/rss+xml'
        );
    };
};

done_testing;
