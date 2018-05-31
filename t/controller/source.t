use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/pod/Moose' ), 'GET /pod/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    ok( my $source = $tx->find_value('//a[text()="Source"]/@href'),
        'contains link to Source' );
    ok( $res = $cb->( GET $source ), "GET $source" );
    ok( $res->code(200), 'code 200' );
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
            surrogate_control => 'max-age=31556952, stale-if-error=2592000',
        }
    );

    ok( $res->content =~ /package Moose/, 'includes Moose package' );

    {
        # Check a URL that is the 'latest', e.g. no version num
        my $uri = '/source/Moose';
        ok( my $res = $cb->( GET $uri ), "GET $uri" );
        is( $res->code, 200, 'code 200' );
        test_cache_headers(
            $res,
            {
                cache_control => 'max-age=3600',
                surrogate_key =>
                    'SOURCE dist=MOOSE author=ETHER content_type=text/html content_type=text',
                surrogate_control =>
                    'max-age=31556952, stale-if-error=2592000',
            }
        );

    }

    {
        # Test the html produced once; test different filetypes below.
        my $prefix = '/source/RJBS/Dist-Zilla-5.043';
        my @tests = ( [ pl => "$prefix/bin/dzil" ], );

        foreach my $test (@tests) {
            my ( $type, $uri ) = @$test;

            ok( my $res = $cb->( GET $uri ), "GET $uri" );
            is( $res->code, 200, 'code 200' );
            my $tx = tx($res);
            like(
                $tx->find_value(q{//div[@class="content"]/pre/code/@class}),
                qr/\blanguage-perl\b/,
                'has pre-block with expected syntax brush'
            );
        }
    }
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

        [ plain => 'README' ],
    );

    foreach my $ft_test (@tests) {
        my ( $filetype, $file ) = @$ft_test;
        ref $file or $file = { path => $file };

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
