use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

my %tests = (
    'net dns'          => 'Net::DNS',
    'DBIx::Class'      => 'DBIx::Class',
    'anyevent'         => 'AnyEvent',
    'AnyEvent'         => 'AnyEvent',
    'anyevent http'    => 'AnyEvent::HTTP',
    'dist zilla'       => 'Dist::Zilla',
    'dbi'              => 'DBI',
    'Perl::Critic'     => 'Perl::Critic',
    'HTML::TokeParser' => 'HTML::TokeParser',
    'HTML::Element' => 'HTML::Element',
    'net::amazon::s3' => 'Net::Amazon::S3',
    'dbix class resultset' => 'DBIx::Class::ResultSet',
);

test_psgi app, sub {
    my $cb = shift;
    while ( my ( $k, $v ) = each %tests ) {

        ok( my $res = $cb->( GET "/search?q=$k" ), 'search for ' . $k );
        my $tx = tx($res);
        my $module
            = $tx->find_value('//div[@class="module-result"][1]/big[1]//a[1]');
        is( $module, $v, "$v is first result" );
    }
};

done_testing;
