use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;

    my $mod_diff = '/diff/file/?target=DOY/Moose-2.0202/lib/Moose.pm'
        . '&source=DOY/Moose-2.0201/lib/Moose.pm';
    my $rel_diff = '/diff/release/DOY/Moose-2.0201/DOY/Moose-2.0202';

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
        'ChangesMETA.jsonMETA.ymlMakefile.PLREADME',
        'Release diff file list'
    );
};

done_testing;
