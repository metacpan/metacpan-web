use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
{
    ok( my $res = $cb->( GET "/changes/release/RWSTAUNER/File-Spec-Native-1.003" ),
        'GET /changes/release/...' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like(
        '//div[@id="content"]//pre[@id="source"]',
        qr/^Revision history for File-Spec-Native/,
        'source view for plain text change log'
    );
}

{
    ok( my $res = $cb->( GET "/changes/distribution/perl" ), 'GET /changes/perl' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like(
        '//div[@id="content"]//div[@class="pod"]//h1[@id="NAME"]//following-sibling::p[position()=1]',
        qr/^perldelta - /,
        'got perldelta for perl release'
    );
}

};

done_testing;
