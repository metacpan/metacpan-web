use strict;
use warnings;
use Test::More;
use aliased 'MetaCPAN::Web::Model::API::Changes::Parser';

my $changes = Parser->load('t/model/changes-tests/dbix-class.changes');

is(
    $changes->{preamble},
    'Revision history for DBIx::Class',
    'correct preamble'
);

my @releases = @{ $changes->{releases} };

is( scalar(@releases), 2, '2 releases' );

my $last = $releases[-1];

is( $last->{version}, '0.08250', 'right version' );

my @groups = @{ $last->{entries} };

is( scalar(@groups), 3, 'got 3 groups' );

{
    note 'Testing Fixes group, which is simple';

    is_deeply( [ map $_->{text}, @groups ], ['New Features / Changes', 'Fixes', 'Misc'],
      'correct groups in correct order' );

    my $fixes = $groups[1];
    my $changelog = $fixes->{entries};
    is( scalar(@$changelog), 8, "8 changes in '$fixes->{text}' group" );

}
{
    note 'testing New Features / Changes, which is slightly harder';
    my ($group) = grep { $_->{text} eq 'New Features / Changes' } @groups;
    my $changelog = $group->{entries};
    is( scalar(@$changelog), 8, 'right number of changes' );
    my $nested = $changelog->[0]->{entries};
    is( scalar @$nested, 7, 'correct number of nested changes' );
    is( $nested->[0]->{text}, 'Multiple has_many prefetch', 'nested entries' );
    is( $changelog->[1]->{text},
      'Massively optimize codepath around ->cursor(), over 10x speedup on some iterating workloads.',
      'after nested' );

    is(
        $nested->[2]->{text},
        'Prefetch of resultsets with arbitrary order (RT#54949, RT#74024, RT#74584)',
        'nested multiline'
    );

}

done_testing;
