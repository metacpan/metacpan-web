use strict;
use warnings;
use lib 't/lib';

use Cpanel::JSON::XS                qw( encode_json );
use MetaCPAN::Web                   ();
use MetaCPAN::Web::Controller::Feed ();
use MetaCPAN::Web::Test qw(
    app GET override_api_response test_cache_headers test_psgi tx
);
use Future ();
use Test::More;
use Test::Warnings ();
use Try::Tiny      qw( catch try );

sub release {
    my ( $author, $name ) = @_;
    return {
        abstract     => 'A canned release',
        author       => $author,
        date         => '2024-01-21T12:00:00.000Z',
        distribution => $name =~ s/-[^-]+\z//r,
        name         => $name,
    };
}

my %api = (
    'release/recent' =>
        { releases => [ release( 'ETHER', 'Moose-2.2207' ) ], total => 1 },

    # More than the 20 releases the dist feed fetches Changes for.
    'release/versions/Moose' => {
        releases => [ map release( 'ETHER', "Moose-2.$_" ),
            reverse 2183 .. 2207 ]
    },
    'author/PERLER'                => { pauseid => 'PERLER', user => 'u1' },
    'release/latest_by_author/PERLER' =>
        { releases => [ release( 'PERLER', 'Foo-Bar-1.0' ) ] },
    'favorite/by_user/u1' => {
        favorites => [ {
            author       => 'ETHER',
            date         => '2024-01-20T12:00:00.000Z',
            distribution => 'Moose',
        } ]
    },
    'distribution/river'     => { river    => {} },
    'release/versions/Empty' => { releases => [] },
);

sub json_res {
    my ( $code, $data ) = @_;
    return [ $code, [ 'Content-Type' => 'application/json' ],
        [ encode_json($data) ] ];
}

# 'timeout' or 'http500' makes /changes/by_releases fail, for the fallback.
my $changes_fail = q{};

# Releases asked of /changes/by_releases, to check the dist feed's cap.
my @changes_requested;

# Canned API responses; anything unstubbed fails rather than hit the network.
override_api_response( sub {
    my ( undef, $req ) = @_;
    my $path = $req->uri->path =~ s{^/v1/}{}r;

    if ( $path eq 'changes/by_releases' ) {
        return Future->fail('timeout') if $changes_fail eq 'timeout';
        return json_res( 500, { code => 500, message => 'boom' } )
            if $changes_fail eq 'http500';
        push @changes_requested, $req->uri->query_param('release');
        return json_res(
            200,
            {
                changes => [
                    map {
                        my ( $author, $release ) = split m{/};
                        my ($version) = $release =~ /-([^-]+)\z/;
                        +{
                            author       => $author,
                            release      => $release,
                            changes_text =>
                                "$version 2024-01-21\n  - Canned change\n",
                        }
                    } $req->uri->query_param('release')
                ]
            }
        );
    }
    return json_res( 404, { code => 404, message => 'Not found' } )
        if $path =~ m{^author/XXX343WI};
    return json_res( 500, { code => 500, message => 'boom' } )
        if $path eq 'release/versions/Broken';
    return json_res( 200, $api{$path} ) if $api{$path};

    fail( 'unstubbed API request: ' . $req->uri );
    die 'unstubbed API request: ' . $req->uri . "\n";
} );

sub get_feed_ok {
    my ( $cb, $test, $extra ) = @_;
    subtest $test => sub {
        ok( my $res = $cb->( GET $test ), $test );
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
            $tx->ok(
                'grep(//item/description, "Changes for")',
                'found changes in recent feed',
            );
            test_cache_headers(
                $res,
                {
                    cache_control => 'max-age=60',
                    surrogate_key =>
                        'RECENT DIST_UPDATES content_type=application/rss+xml content_type=application',
                    surrogate_control =>
                        'max-age=31556952, stale-while-revalidate=86400, stale-if-error=2592000',
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
                'grep(//item/description, "PERLER \+\+ed (\S+) from ([A-Z]+)")',
                'found favorites in author feed',
            );
            $tx->ok(
                'grep(//item/title, "PERLER has released (.+)")',
                'found releases in author feed',
            );
            test_cache_headers(
                $res,
                {
                    cache_control => 'max-age=3600',
                    surrogate_key =>
                        'author=PERLER content_type=application/rss+xml content_type=application',
                    surrogate_control =>
                        'max-age=31556952, stale-while-revalidate=86400, stale-if-error=2592000',
                }
            );
        }
    );
    @changes_requested = ();
    get_feed_ok(
        $cb,
        '/dist/Moose/releases.rss',
        sub {
            my ( $res, $tx ) = @_;
            $tx->ok( '//rss[@version="2.0"]/channel/item',
                'dist feed is RSS 2.0' );
            is_deeply(
                \@changes_requested,
                [ map "ETHER/Moose-2.$_", reverse 2188 .. 2207 ],
                'changes fetched for the newest 20 releases only'
            );
            $tx->is( 'count(//item)', 25, 'feed lists all releases' );
            $tx->like(
                '//item[1]/description',
                qr/Changes for/,
                'newest release has changes'
            );
            test_cache_headers(
                $res,
                {
                    cache_control => 'max-age=3600',
                    surrogate_key =>
                        'dist=MOOSE content_type=application/rss+xml content_type=application',
                    surrogate_control =>
                        'max-age=31556952, stale-while-revalidate=86400, stale-if-error=2592000',
                }
            );
        }
    );

    subtest '/dist/Moose/releases.atom' => sub {
        my $res = $cb->( GET '/dist/Moose/releases.atom' );
        is( $res->code, 200, 'code 200' );
        is(
            $res->header('content-type'),
            'application/atom+xml; charset=UTF-8',
            'Content-type is application/atom+xml'
        );
    };

    test_redirect( $cb, 'oalders' );

    subtest 'author 404' => sub {
        my $res = $cb->( GET '/author/XXX343WI^^^/activity.rss' );
        is( $res->code, 404, '404 when author does not exist' );
    };

    subtest 'dist versions API error' => sub {
        my $res = $cb->( GET '/dist/Broken/releases.rss' );
        is( $res->code, 500, '500 rather than an empty feed' );
    };

    subtest 'dist with no releases' => sub {
        my $res = $cb->( GET '/dist/Empty/releases.rss' );
        is( $res->code, 200, 'empty feed, not an error' );
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
            surrogate_key     => 'content_type=text/html content_type=text',
            surrogate_control =>
                'max-age=31556952, stale-while-revalidate=86400, stale-if-error=2592000',
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

for my $mode (qw( timeout http500 )) {
    $changes_fail = $mode;
    test_psgi app, sub {
        my $cb = shift;
        subtest "Changes $mode" => sub {
            for my $url ( '/dist/Moose/releases.rss', '/recent.rss' ) {
                get_feed_ok(
                    $cb, $url,
                    sub {
                        my ( $res, $tx ) = @_;
                        $tx->ok( '//item', 'entries still present' );
                        $tx->not_ok(
                            'grep(//item/description, "Changes for")',
                            'feed served without changes'
                        );
                        test_cache_headers(
                            $res,
                            {
                                surrogate_control =>
                                    'max-age=300, stale-while-revalidate=86400, stale-if-error=2592000',
                            }
                        );
                    }
                );
            }
        };
    };
}

## We are not doing retries as if API is loaded we do not want to retry
# do this last so the override_api_response only affects this
# my $how_many = 0;
# override_api_response(
#     if => sub { !$how_many++ },    # fail only once
#     sub { Future->fail('Error'); },
# );
# test_psgi app, sub {
#     my $cb = shift;
#     subtest 'retry on transient failure' => sub {
#         ok( my $res = $cb->( GET '/recent.rss' ) );
#         is( $res->code, 200, 'code 200' );
#         is(
#             $res->header('content-type'),
#             'application/rss+xml; charset=UTF-8',
#             'Content-type is application/rss+xml'
#         );
#     };
# };

done_testing;
