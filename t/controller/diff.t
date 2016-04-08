use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;

    my $mod_diff = '/diff/file/?target=ETHER/Moose-2.1605/lib/Moose.pm'
        . '&source=ETHER/Moose-2.1604/lib/Moose.pm';
    my $rel_diff = '/diff/release/ETHER/Moose-2.1604/ETHER/Moose-2.1605';

    ok( my $res = $cb->( GET $mod_diff ), 'GET module diff' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);

    is( $tx->find_value('//ul[@class="diff-ul"]//li/a'),
        'lib/Moose.pm', 'Module diff file list' );

    ok( $res = $cb->( GET $rel_diff ), 'GET release diff' );
    is( $res->code, 200, 'code 200' );
    $tx = tx($res);

    is(
        $tx->find_value('//ul[@class="diff-ul"]//li[position() <= 5]/a'),
        'ChangesLICENSEMANIFESTMETA.jsonMETA.yml',
        'Release diff file list'
    );
};

done_testing;
