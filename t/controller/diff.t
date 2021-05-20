use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test qw( app GET test_psgi tx );

test_psgi app, sub {
    my $cb = shift;

    my $mod_diff
        = '/release/ETHER/Moose-2.1605/diff/ETHER/Moose-2.1604/lib/Moose.pm';
    my $rel_diff = '/release/ETHER/Moose-2.1605/diff/ETHER/Moose-2.1604';

    ok( my $res = $cb->( GET $mod_diff ), 'GET module diff' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);

    is( $tx->find_value('//table[contains(@class, "diff-list")]//td[1]/a'),
        'lib/Moose.pm', 'Module diff file list' );

    ok( $res = $cb->( GET $rel_diff ), 'GET release diff' );
    is( $res->code, 200, 'code 200' );
    $tx = tx($res);

    is(
        $tx->find_value(
            '//table[contains(@class, "diff-list")]//tr[position() <= 5]/td[1]/a'
        ),
        'ChangesLICENSEMANIFESTMETA.jsonMETA.yml',
        'Release diff file list'
    );
};

done_testing;
