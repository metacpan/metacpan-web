use strict;
use warnings;

use Test::More;
use MetaCPAN::Web ();

my $model = MetaCPAN::Web->model('API::Lab');

my $report = $model->fetch_latest_distros( 2, 'OALDERS' )->get;
is( keys %{ $report->{distros} }, 2, 'gets two distros' );

my $dependencies = $model->dependencies('HTML::Restrict');
isa_ok( $dependencies, 'Future', 'dependencies' );
my @foo = $dependencies->get;
cmp_ok( @{ $dependencies->get }, '>', 10, 'finds at least 11 deps' );

done_testing;
