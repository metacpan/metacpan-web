use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi tx );

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/recent' ), 'GET /recent' );
    is( $res->code, 200, 'code 200' );

    my $tx = tx($res);
    ok(
        my $release = $tx->find_value(
            '//table[contains(@class, "table-releases")][1]/tbody/tr[1]/td[@class="name"]//a[1]/@href'
        ),
        'contains a release'
    );
    ok( $res = $cb->( GET $release ), "GET $release" );
    is( $res->code, 200, 'code 200' );

};

done_testing;
