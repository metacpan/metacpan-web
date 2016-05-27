use strict;
use warnings;

use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    {
        my $url = '/changes/release/RWSTAUNER/File-Spec-Native-1.003';
        my $res = $cb->( GET $url );
        is( $res->code, 200, "200 on $url" );
        my $tx = tx( $res, { css => 1 } );
        $tx->like(
            'div.content pre#source',
            qr/^Revision history for File-Spec-Native/,
            'source view for plain text change log'
        );
    }

    {
        my $url = '/changes/release/SHAY/perl-5.22.2';
        my $res = $cb->( GET $url );
        is( $res->code, 200, "200 on $url" );
        my $tx = tx($res);
        $tx->like(
            '//title',
            qr{^pod/perldelta.pod - },
            'got perldelta for perl release'
        );
    }

    {
        my $missing = 'test-dist-name-that-does-not-exist-i-hope';
        my $url     = "/changes/distribution/$missing";
        my $res     = $cb->( GET $url );
        is( $res->code, 404, "404 on $url" );
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
