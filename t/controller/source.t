use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_cache_headers test_psgi tx );
use Test::More;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/pod/Moose' ), 'GET /pod/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    ok( my $source = $tx->find_value('//a[text()="Source"]/@href'),
        'contains link to Source' );
    ok( $res = $cb->( GET $source ), "GET $source" );
    ok( $res->code(200),             'code 200' );
    is(
        $res->header('Content-Type'),
        'text/html; charset=utf-8',
        'Content-type text/html; charset=utf-8'
    );
    test_cache_headers(
        $res,
        {
            cache_control => 'max-age=3600',
            surrogate_key =>
                'SOURCE dist=MOOSE author=ETHER content_type=text/html content_type=text',
            surrogate_control =>
                'max-age=31556952, stale-while-revalidate=86400, stale-if-error=2592000',
        }
    );

    ok( $res->content =~ /package Moose/, 'includes Moose package' );

    {
        # Check a URL that is the 'latest', e.g. no version num
        my $uri = '/module/Moose/source';
        ok( my $res = $cb->( GET $uri ), "GET $uri" );
        is( $res->code, 200, 'code 200' );
        test_cache_headers(
            $res,
            {
                cache_control => 'max-age=3600',
                surrogate_key =>
                    'SOURCE dist=MOOSE author=ETHER content_type=text/html content_type=text',
                surrogate_control =>
                    'max-age=31556952, stale-while-revalidate=86400, stale-if-error=2592000',
            }
        );

        # Check the "Raw code" and "Permalink" URLs
        my @versioned_link_tests = (
            {
                xpath    => '//a[text()="Raw code"]/@href',
                expected => qr{\bapi\.metacpan\.org/v1/},
                desc     => 'raw code points to fastapi'
            },
            {
                xpath => '//a[text()="Raw code"]/@href',
                #<<<       Maintainer vvvvv       vvvvvvvvvvvvvvvv Dist version number #>>>
                expected => qr{source/[^/]+/Moose-\d+(?:\.\d+){0,}/},
                desc => 'raw code includes specific version'
            },

            {
                xpath    => '//a[text()="Permalink"]/@href',
                expected => qr{\brelease/[^/]+/Moose-\d+(?:\.\d+){0,}/source},
                desc     => 'Permalink includes specific version'
            },
        );

        my $versioned_link_tx = tx($res);
        foreach my $versioned_link_test (@versioned_link_tests) {
            like(
                $versioned_link_tx->find_value(
                    $versioned_link_test->{xpath}
                ),
                $versioned_link_test->{expected},
                $versioned_link_test->{desc},
            );
        }
    }

    {
        # Test Markdown and non-Markdown html produced once each; test
        # different filetypes below.
        my @tests = (
            {
                uri      => '/release/RJBS/Dist-Zilla-5.043/source/bin/dzil',
                xpath    => '//main/pre/code/@class',
                expected => qr/\blanguage-perl\b/,
                desc     => 'has pre-block with expected syntax brush',
            },
            {
                uri      => '/release/ETHER/Moose-2.1005/view/README.md',
                xpath    => '//h1[@id="moose"]',
                expected => qr/^Moose$/,
                desc     => 'markdown rendered as HTML',
            },
        );

        foreach my $test (@tests) {
            ok( my $res = $cb->( GET $test->{uri} ), "GET $test->{uri}" );
            is( $res->code, 200, 'code 200' );
            like( tx($res)->find_value( $test->{xpath} ),
                $test->{expected}, $test->{desc}, );
        }
    }
    # When a dist exists but the source path doesn't, the internal forward
    # to the view action sets req->args to [author, versioned-release-name].
    # The 404 search suggestion should use the distribution name from the
    # stash, not those internal values.
    {
        my $url = '/dist/Moose/source/no/such/path';
        ok( my $res = $cb->( GET $url ), "GET $url" );
        is( $res->code, 404, "404 on $url" );

        my $tx    = tx($res);
        my $xpath = '//main[contains-token(@class, "error-page")]//a[contains(@href, "/search?q=")]';
        is(
            $tx->find_value($xpath),
            'Moose',
            'search suggestion uses dist name, not author or versioned release'
        );
        is(
            $tx->find_value("$xpath/\@href"),
            '/search?q=Moose',
            'search link URL contains only the distribution name'
        );
    }

    subtest 'markdown documentation link in browse view' => sub {
        my $uri = '/release/ETHER/Moose-2.1005/source';
        ok( my $res = $cb->( GET $uri ), "GET $uri" );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);
        $tx->ok(
            '//td[contains-token(@class, "name")]/a[text()="README.md"]',
            'browse view has README.md file entry',
        );
        ok(
            $tx->find_value(
                '//tr[.//a[text()="README.md"]]/td[contains-token(@class, "documentation")]/strong/a[text()="README.md"]/@href'
            ),
            'browse view shows documentation link for README.md',
        );
    };

    subtest 'markdown Documentation View link in source view' => sub {
        my $uri = '/release/ETHER/Moose-2.1005/source/README.md';
        ok( my $res = $cb->( GET $uri ), "GET $uri" );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);
        ok(
            $tx->find_value('//a[text()="Documentation View"]/@href'),
            'source view has Documentation View link for markdown file',
        );
        like(
            $tx->find_value('//a[text()="Documentation View"]/@href'),
            qr{/view/README\.md$},
            'Documentation View link points to rendered view',
        );
    };
};

{
    # Test filetype detection.  This is based on file attributes so we don't
    # need to do the API hits to test each type.
    my @tests = (
        [ perl => 'lib/Template/Manual.pod' ],    # pod
        [ perl => 'lib/Dist/Zilla.pm' ],
        [ perl => 'Makefile.PL' ],

        [ javascript => 'META.json' ],
        [ javascript => 'script.js' ],

        [ yaml => 'META.yml' ],
        [ yaml => 'config.yaml' ],

        [ c => 'foo.c' ],
        [ c => 'bar.h' ],
        [ c => 'baz.xs' ],

        [ cpanchanges => 'Changes' ],

        [ perl => { path => 'bin/dzil', mime => 'text/x-script.perl' } ],

        # There wouldn't normally be a file with no path
        # but that doesn't mean this shouldn't work.
        [ perl => { mime => 'text/x-script.perl' } ],

        [ markdown => 'CONTRIBUTING.md' ],

        [ plain => 'README' ],
    );

    foreach my $ft_test (@tests) {
        my ( $filetype, $file ) = @$ft_test;
        ref $file or $file = { path => $file };
        $file = MetaCPAN::Web::Role::FileData->_groom_file($file);

        is
            MetaCPAN::Web::Controller::Source->detect_filetype($file),
            $filetype,
            "detected filetype '$filetype' for: " . join q{ }, %$file;
    }

    {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        # Test no 'path' and no 'mime'.
        is MetaCPAN::Web::Controller::Source->detect_filetype( {} ),
            'plain', 'default to plain text';

        is scalar(@warnings), 0, 'no warnings when path and mime are undef'
            or diag explain \@warnings;
    }
}

done_testing;
