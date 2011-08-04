use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/module/Moose" ), 'GET /module/Moose' );
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

    # should we upload a dist with one of each file just for testing?
    {
        my $prefix = '/source/RJBS/Dist-Zilla-4.200012';
        my @tests = (
            [ pl    => '/source/ABW/Template-Toolkit-2.22/lib/Template/Manual.pod' ], # pod
            [ pl    => "$prefix/lib/Dist/Zilla.pm" ],
            [ pl    => "$prefix/bin/dzil" ],
            [ pl    => "$prefix/Makefile.PL" ],
            [ js    => "$prefix/META.json" ],
            [ yaml  => "$prefix/META.yml" ],
            [ plain => "$prefix/README" ],
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

done_testing;
