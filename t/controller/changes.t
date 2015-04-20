use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    {
        ok(
            my $res = $cb->(
                GET '/changes/release/RWSTAUNER/File-Spec-Native-1.003'
            ),
            'GET /changes/release/...'
        );
        is( $res->code, 200, 'code 200' );
        my $tx = tx( $res, { css => 1 } );
        $tx->like(
            'div.content pre#source',
            qr/^Revision history for File-Spec-Native/,
            'source view for plain text change log'
        );
    }

    {
        ok( my $res = $cb->( GET '/changes/distribution/perl' ),
            'GET /changes/distribution/perl' );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);
        $tx->like(
            '//title',
            qr/^perldelta - /,
            'got perldelta for perl release'
        );
    }

    {
        my $missing = 'test-dist-name-that-does-not-exist-i-hope';
        ok( my $res = $cb->( GET "/changes/distribution/$missing" ),
            "GET /changes/$missing" );
        is( $res->code, 404, 'code 404' );
        my $tx = tx($res);
        $tx->like(
            '//div[@id="not-found"]',
            qr/Change log not found for release.+Try the release info page:/,
            'Suggest release info page for not-found dist.'
        );
        $tx->like(
            qq{//div[\@id="not-found"]//p[\@class="suggestion"]//a[text()="$missing"]//\@href},
            qr{/$missing$}, 'link to suggested release',
        );
    }

};

done_testing;
