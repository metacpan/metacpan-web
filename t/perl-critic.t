use strict;
use warnings;

use Test::More;
use Test::Perl::Critic;

my @files = ('lib/MetaCPAN/Sitemap.pm');

foreach my $file (@files) {
    critic_ok( $file, $file );
}

done_testing();
