#!/usr/bin/env perl

use strict;
use warnings;

# This test is _really_ slow on Travis with Devel::Cover running.  Also,
# there's really no reason to run this when coverage tests are running, since
# it's not bringing anything to the table.

use Test::Code::TidyAll qw( tidyall_ok );
use Test::More
    do { $ENV{COVERAGE} ? ( skip_all => 'skip under Devel::Cover' ) : () };
tidyall_ok( verbose => $ENV{TEST_TIDYALL_VERBOSE} );

done_testing();
