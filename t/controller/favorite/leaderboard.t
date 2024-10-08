use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi tx );
use Test::More;

test_psgi app, sub {
    my $cb = shift;
    {
        ok(
            my $res = $cb->( GET '/favorite/leaderboard' ),
            'GET leaderboard',
        );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);
        $tx->ok(
            '//table[contains-token(@class, "table-releases")]//td[contains-token(@class, "name")]//a',
            sub {
                my $anchor = shift;
                $anchor->is(
                    './@href',
                    '/dist/' . $anchor->node->textContent,
                    'href points to release'
                );
            },
            'links point to release'
        );
    }
};

done_testing;
