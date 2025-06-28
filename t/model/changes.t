use strict;
use warnings;
use lib 't/lib';

use Test::More;

use MetaCPAN::Web ();

my $model = MetaCPAN::Web->model('API::Changes');

my $changelog = <<'END_CHANGES';
Prelude

v1.3
    - first change
    - second change

v1.2-TRIAL
    - change from dev release

v1.0
    - change from old release

v1.1-TRIAL
    - change from unordered old dev release

END_CHANGES

{
    my $changes = $model->_relevant_changes(
        $changelog,
        {
            version => 'v1.3',
        }
    );

    is @$changes,                1,      'got one release';
    is $changes->[0]->{version}, 'v1.3', 'release is requested version';
}
{
    my $changes = $model->_relevant_changes(
        $changelog,
        {
            include_dev => 1,
            version     => 'v1.3',
        }
    );

    is @$changes,                2,      'got two releases including dev';
    is $changes->[0]->{version}, 'v1.3', 'first release is requested version';
    is $changes->[1]->{version}, 'v1.2-TRIAL',
        'second release is dev release';
}

my $rev_changelog = <<'END_CHANGES';
Prelude

v1.1-TRIAL
    - change from unordered old dev release

v1.0
    - change from old release

v1.2-TRIAL
    - change from dev release

v1.3
    - first change
    - second change

END_CHANGES

{
    my $changes = $model->_relevant_changes(
        $rev_changelog,
        {
            version => 'v1.3',
        }
    );

    is @$changes, 1, 'reversed: got one release';
    is $changes->[0]->{version}, 'v1.3',
        'reversed: release is requested version';
}
{
    my $changes = $model->_relevant_changes(
        $changelog,
        {
            include_dev => 1,
            version     => 'v1.3',
        }
    );

    is @$changes, 2, 'reversed: got two releases including dev';
    is $changes->[0]->{version}, 'v1.3',
        'reversed: first release is requested version';
    is $changes->[1]->{version}, 'v1.2-TRIAL',
        'reversed: second release is dev release';
}

my $scramble_changelog = <<'END_CHANGES';
Prelude

v1.0
    - change from old release

v1.3
    - first change
    - second change

v1.1-TRIAL
    - change from old dev release

v1.2-TRIAL
    - change from dev release

END_CHANGES

{
    my $changes = $model->_relevant_changes(
        $scramble_changelog,
        {
            version => 'v1.3',
        }
    );

    is @$changes, 1, 'scrambled: got one release';
    is $changes->[0]->{version}, 'v1.3',
        'scrambled: release is requested version';
}
{
    my $changes = $model->_relevant_changes(
        $scramble_changelog,
        {
            include_dev => 1,
            version     => 'v1.3',
        }
    );

    is @$changes, 3, 'scrambled: got two releases including dev';
    is $changes->[0]->{version}, 'v1.3',
        'scrambled: first release is requested version';
    is $changes->[1]->{version}, 'v1.2-TRIAL',
        'scrambled: second release is dev release';
    is $changes->[2]->{version}, 'v1.1-TRIAL',
        'scrambled: third release is dev release';
}

done_testing;
