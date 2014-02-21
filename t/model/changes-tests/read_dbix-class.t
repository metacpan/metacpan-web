use strict;
use warnings;
use Test::More;
use aliased 'MetaCPAN::Web::Model::API::Changes::Parser';

my $changes = Parser->load('t/model/changes-tests/dbix-class.changes');

is(
    $changes->preamble,
    'Revision history for DBIx::Class',
    'correct preamble'
);

my @releases = $changes->releases;

is( scalar(@releases), 2, "2 releases" );

my $last = $releases[-1];

is( $last->version, "0.08250", "right version" );

my @groups = $last->groups;

is( scalar(@groups), 3, "got 3 groups" );

{
    note "Testing Fixes group, which is simple";

    my $first = $groups[0];
    is( $first, "Fixes", "right title for first group" );

    my $changelog = $last->changes($first);
    is( scalar(@$changelog), 8, "8 changes in '$first' group" );

}
{
    note "testing New Features / Changes, which is slightly harder";
    my $changelog = $last->changes('New Features / Changes');
    is( scalar(@$changelog), 15, "right number of changes" );
    is( $changelog->[1], "- Multiple has_many prefetch",
        "nested preserve -" );

    is(
        $changelog->[3],
        "- Prefetch of resultsets with arbitrary order (RT#54949, RT#74024, RT#74584)",
        "right nested multiline"
    );

}

done_testing;
