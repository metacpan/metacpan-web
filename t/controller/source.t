use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/pod/Moose" ), 'GET /pod/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    ok( my $source = $tx->find_value('//a[text()="Source"]/@href'),
        'contains link to Source' );
    ok( $res = $cb->( GET $source ), "GET $source" );
    ok( $res->code(200), 'code 200' );
    is( $res->header('Content-Type'),
        'text/html; charset=utf-8',
        'Content-type text/html; charset=utf-8'
    );
    ok( $res->content =~ /package Moose/, 'includes Moose package' );

    {
        # Test the html produced once; test different filetypes below.
        my $prefix = '/source/RJBS/Dist-Zilla-4.200012';
        my @tests = (
            [ pl    => "$prefix/bin/dzil" ],
        );

        foreach my $test ( @tests ) {
            my ( $type, $uri ) = @$test;

            ok( my $res = $cb->( GET $uri ), "GET $uri" );
            is( $res->code, 200, 'code 200' );
            my $tx = tx($res);
            ok( my $source = $tx->find_value(qq{//div[\@class="content"]/pre[starts-with(\@class, "brush: $type; ")]}),
                'has pre-block with expected syntax brush' );
        }
    }
};

{
    # Test filetype detection.  This is based on file attributes so we don't
    # need to do the API hits to test each type.
    my @tests = (
        [ pl    => 'lib/Template/Manual.pod' ], # pod
        [ pl    => "lib/Dist/Zilla.pm" ],
        [ pl    => "Makefile.PL" ],

        [ js    => "META.json" ],
        [ js    => "script.js" ],

        [ yaml  => "META.yml" ],
        [ yaml  => "config.yaml" ],

        [ c     => "foo.c" ],
        [ c     => "bar.h" ],
        [ c     => "baz.xs" ],

        [ cpanchanges => 'Changes' ],

        [ pl    => { path => "bin/dzil", mime => "text/x-script.perl" }],

        # There wouldn't normally be a file with no path
        # but that doesn't mean this shouldn't work.
        [ pl    => { mime => "text/x-script.perl" }],

        [ plain => "README" ],
    );

    foreach my $ft_test ( @tests ){
        my ($filetype, $file) = @$ft_test;
        ref $file or $file = { path => $file };

        is
            MetaCPAN::Web::Controller::Source->detect_filetype($file),
            $filetype,
            "detected filetype '$filetype' for: " . join ' ', %$file;
    }

    {
        my @warnings;
        local $SIG{__WARN__} = sub { push @warnings, $_[0] };

        # Test no 'path' and no 'mime'.
        is MetaCPAN::Web::Controller::Source->detect_filetype({}),
            'plain', 'default to plain text';

        is scalar(@warnings), 0, 'no warnings when path and mime are undef'
            or diag explain \@warnings;
    }
}

done_testing;
