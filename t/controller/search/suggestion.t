use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

my %tests = (
    'DBIx:Class:::ResultSet' => 'DBIx::Class::ResultSet',
    'DBIx::Class:ResultSet'  => 'DBIx::Class::ResultSet',
    'DBIx:Class'             => 'DBIx::Class',
);

test_psgi app, sub {
    my $cb = shift;
    while ( my ( $k, $v ) = each %tests ) {

        ok( my $res = $cb->( GET "/search?q=$k" ), 'search for ' . $k );
        my $tx = tx($res);
        use Data::Dump qw/dump/;
        warn dump(
            $tx->find_value(
                '//div[@class="no-results"]//div[@class="alert alert-error"]')
        );
        my $module
            = $tx->find_value(
            '//div[@class="no-results"]//div[@class="alert alert-error"]//a[1]'
            );
        is( $module, $v, "get no result page with suggestion" );
    }
};

done_testing;
