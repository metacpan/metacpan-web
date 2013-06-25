use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/changes/release/RWSTAUNER/File-Spec-Native-1.003" ),
        'GET /changes/release/...' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like(
        '//div[@id="content"]//pre[@id="source"]',
        qr/^Revision history for File-Spec-Native/,
        'source view for plain text change log'
    );

};

done_testing;
