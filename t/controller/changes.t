use strict;
use warnings;

use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi tx );

test_psgi app, sub {
    my $cb = shift;
    {
        my $url = '/release/RWSTAUNER/File-Spec-Native-1.003/changes';
        my $res = $cb->( GET $url );
        is( $res->code, 200, "200 on $url" );
        my $tx = tx($res);
        $tx->like(
            '//div[contains-token(@class, "content")]//pre[@id="source"]',
            qr/^Revision history for File-Spec-Native/,
            'source view for plain text change log'
        );
    }

    {
        my $url = '/release/SHAY/perl-5.22.2/changes';
        my $res = $cb->( GET $url );
        is( $res->code, 200, "200 on $url" );
        my $tx = tx($res);
        $tx->like(
            '//title',
            qr/^perldelta - /,
            'got perldelta for perl release'
        );
    }

    {
        my $missing = 'test-dist-name-that-does-not-exist-i-hope';
        my $url     = "/dist/$missing/changes";
        my $res     = $cb->( GET $url );
        is( $res->code, 404, "404 on $url" );
        my $tx = tx($res);
        $tx->like(
            '//div[contains-token(@class,"error-page")]',
            qr/Change log not found for release.+Try the release info page:/,
            'Suggest release info page for not-found dist.'
        );
        $tx->like(
            qq{//div[contains-token(\@class,"error-page")]//p[\@class="suggestion"]//a[text()="$missing"]//\@href},
            qr{/$missing$}, 'link to suggested release',
        );
    }

};

done_testing;
