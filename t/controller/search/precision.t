use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web::Test qw( app GET test_psgi tx );
use Test::More;

my %tests = (
    'net dns'              => 'Net::DNS',
    'DBIx::Class'          => 'DBIx::Class',
    'anyevent'             => 'AnyEvent',
    'AnyEvent'             => 'AnyEvent',
    'anyevent http'        => 'AnyEvent::HTTP',
    'Dist::Zilla'          => 'Dist::Zilla',
    'dbi'                  => 'DBI',
    'Perl::Critic'         => 'Perl::Critic',
    'HTML::TokeParser'     => 'HTML::TokeParser',
    'HTML::Element'        => 'HTML::Element',
    'net::amazon::s3'      => 'Net::Amazon::S3',
    'dbix class resultset' => 'DBIx::Class::ResultSet',
);

my %authors = (
    '  LLAP   ' => 'LLAP',
    'PERLER   ' => 'PERLER',
    '    NEILB' => 'NEILB',
    'RWSTAUNER' => 'RWSTAUNER',
    ' OALDERS ' => 'OALDERS',
);

test_psgi app, sub {
    my $cb = shift;
    for my $k ( sort keys %tests ) {
        my $v = $tests{$k};
        ok( my $res = $cb->( GET "/search?q=$k" ), 'search for ' . $k );
        my $tx = tx($res);
        my $module
            = $tx->find_value(
            '//div[contains-token(@class, "module-result")][1]/h3[1]/a[1]');
        is( $module, $v, "$v is first result" );
    }

    for my $k ( sort keys %authors ) {
        ok( my $res = $cb->( GET "/search?q=$k" ), qq{search for "$k"} );
        my $v  = $authors{$k};
        my $tx = tx($res);
        my $author
            = $tx->find_value(
            '//div[contains-token(@class,"author-results")]/ul[contains-token(@class, "authors")][contains-token(@class, "clearfix")]/li[1]/a[1]'
            );
        like( $author, qr/\b$v\b/, "$v is first result" );
    }
};

done_testing;
