use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi tx );
use Test::More;

test_psgi app, sub {
    my $cb = shift;
    {
        ok( my $res = $cb->( GET '/' ), 'GET /' );
        is( $res->code, 200, 'code 200' );

        my $xpc = tx($res)->xpc;

        my @assets = grep m{^/}, map $_->value,
            $xpc->findnodes(q[//script/@src]),
            $xpc->findnodes(q[//link[@rel="stylesheet"]/@href]);

        ok( ( grep /\.js$/,  @assets ), 'assets include a js file' );
        ok( ( grep /\.css$/, @assets ), 'assets include a css file' );

        for my $asset (@assets) {
            ok( my $res = $cb->( GET $asset ), "GET $asset" );
            is( $res->code, 200, 'code 200' );
        }
    }
};

done_testing;
