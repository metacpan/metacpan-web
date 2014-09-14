use strict;
use warnings;
use Test::More;
use aliased 'MetaCPAN::Web::Model::API::Changes::Parser';

my $changes = Parser->load('t/model/changes-tests/moose.changes');

is(
    $changes->{preamble},
    'Also see Moose::Manual::Delta for more details of, and workarounds
for, noteworthy changes.', 'correct preamble'
);

my @releases = @{ $changes->{releases} };

is( scalar(@releases), 2, '2 releases' );

my $last = $releases[-1];

is( $last->{version}, '2.1005', 'right version' );

my @groups = @{ $last->{entries} };

is( scalar(@groups), 2, 'got 2 groups' ) or diag explain \@groups;

{
    note 'Testing BUG FIXES group, which is simple';

    my $bug_fixes = $groups[1];
    is( $bug_fixes->{text}, 'BUG FIXES', 'right title for second group' );

    my $changelog = $bug_fixes->{entries};
    is( scalar(@$changelog), 2, "2 changes in '$bug_fixes->{text}' group" );
    is( $changelog->[0]->{text},
        'If a role consumed another role, we resolve method conflicts just like a '
            . 'class consuming a role, but when metaclass compat tried to fix up '
            . 'metaclass roles, we were putting all methods into one composite role and '
            . 'allowing methods in the metaclass roles to conflict. Now we resolve them '
            . 'as we should. (Jesse Luehrs, PR#27)' );

}
{
    note 'testing ENHANCEMENTS';
    my ($enhancements) = grep { $_->{text} eq 'ENHANCEMENTS' } @groups;
    my $changelog = $enhancements->{entries};
    is( scalar(@$changelog), 1, 'right number of changes' );
    is(
        $changelog->[0]->{text},
        'add_method now accepts blessed subs (Graham Knop, PR#28)',
        'Parsed groups correctly'
    );
}

done_testing;
