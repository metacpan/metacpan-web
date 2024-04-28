#!/usr/bin/env perl

use strict;
use warnings;

# This test is _really_ slow with Devel::Cover running.  Also,
# there's really no reason to run this when coverage tests are running, since
# it's not bringing anything to the table.
use Test::More $ENV{COVERAGE}
    ? ( skip_all => 'skip under Devel::Cover' )
    : ();

use File::Temp ();

use Test::Code::TidyAll qw( tidyall_ok );

my %opts = ( verbose => $ENV{TEST_TIDYALL_VERBOSE}, );

if ( -e '.tidyall.d' ? !-w _ : !-w '.' ) {
    $opts{data_dir} = File::Temp::tempdir(
        TEMPLATE => 'tidyall-XXXXXX',
        TMPDIR   => 1,
        CLEANUP  => 1,
    );
}

tidyall_ok(%opts);

done_testing();
