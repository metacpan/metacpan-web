use strict;
use warnings;
use lib 't/lib';

use MetaCPAN::Web ();
use Test::More;

my $model = MetaCPAN::Web->model('API::CVE');

subtest 'has cves' => sub {
    my $result = $model->get( 'SRI', 'Mojolicious-9.30' )->get;
    my @cves = sort { $a->{reported} cmp $b->{reported} } $result->{cves}->@*;
    my $cve  = $cves[0];
    ok( $cve->{cpansa_id},   'cpansa_id' );
    ok( $cve->{cves},        'cves' );
    ok( $cve->{description}, 'description' );
    is( $cve->{severity}, undef, 'undef severity' );
    ok( $cve->{reported},   'reported date' );
    ok( $cve->{references}, 'references' );
};

subtest 'no cves' => sub {
    my $empty = $model->get( 'OALDERS', 'HTML-Restrict-3.0.2' )->get;
    is_deeply( $empty->{cves}, [], 'cve list is empty' );
};

done_testing;
