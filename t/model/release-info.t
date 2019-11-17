use strict;
use warnings;

use lib 't/lib';
use Test::More;
use TestContext qw( get_context );
use Module::Runtime qw( use_module );

my $model = use_module('MetaCPAN::Web::Model::ReleaseInfo')->new;

my $rt_prefix = $model->rt_url_prefix;

sub bugtracker {
    return { resources => { bugtracker => {@_} } };
}

sub normalize_issues_ok {
    my ( $release, $bugs, $exp, $desc ) = @_;
    my $normalized = $model->normalize_issues(
        { distribution => 'X', %$release },

        # Default to rt url, but let data override.
        { bugs => { rt => { source => "${rt_prefix}X", %$bugs } } },
    );
    is_deeply $normalized, $exp, $desc;
}

subtest 'normalize_issues' => sub {

    normalize_issues_ok(
        {},
        { active => 11 },
        { url    => "${rt_prefix}X", active => 11 },
        'no resources: rt url and count',
    );

    {
        my $bt = {
            web    => 'http://issues',
            mailto => 'foo@example.com',
        };

        normalize_issues_ok(
            bugtracker(%$bt),
            { active => 9 },
            { url    => $bt->{web} },
            'prefer bugtracker.web',
        );

        delete $bt->{web};

        normalize_issues_ok(
            bugtracker(%$bt),
            { active => 9 },
            { url    => 'mailto:' . $bt->{mailto} },
            'prefer bugtracker.mailto w/o web',
        );

        delete $bt->{mailto};

        normalize_issues_ok(
            bugtracker(%$bt),
            { active => 9 },
            { url    => "${rt_prefix}X", active => 9 },
            'assume rt w/o web or mailto (and include counts)',
        );
    }

    # Examples found in the api (distinct after replacing dist name with X):
    foreach my $url ( qw(
        http://rt.cpan.org
        http://rt.cpan.org/Dist/Display.html?Name=X
        http://rt.cpan.org/Dist/Display.html?Queue=X
        http://rt.cpan.org/Dist/Display.html?Status=Active&Queue=X
        http://rt.cpan.org/NoAuth/Bugs.html?Auth=X
        http://rt.cpan.org/NoAuth/Bugs.html?Dist=X
        http://rt.cpan.org/NoAuth/ReportBug.html?Queue=X
        http://rt.cpan.org/Public/Bug/Report.html?Queue=X
        http://rt.cpan.org/Public/Dist/Display.html?Name=X
        http://rt.cpan.org/Public/Dist/Display.html?Name=${dist}
        http://rt.cpan.org/Public/Dist/Display.html?X
        http://rt.cpan.org/Public/Dist/Display.html?Queue=X
        http://rt.cpan.org/Public/Dist/Display.html?Status=Active&Name=X
        http://rt.cpan.org/Ticket/Create.html?Queue=X
    ) )
    {
        normalize_issues_ok(
            bugtracker( web => $url ),
            { active => 12 },
            { url    => $url, active => 12 },
            "alternate rt url ($url): same url and rt count",
        );
    }

    normalize_issues_ok(
        bugtracker( web => 'http://canhaz' ),
        { source => 'http://canhaz', active => 13 },
        { url    => 'http://canhaz', active => 13 },
        'custom bugtracker.web with matching counts: use both'
    );

    # If a dist specifies a web, and then later removes it.
    normalize_issues_ok(
        {},
        { source => 'anything://else', active => 13 },
        { url    => "${rt_prefix}X" },
        'no resources: rt url; counts from old source: no count'
    );

    foreach my $url ( qw(
        https://github.com/user/repo
        http://github.com/user/repo
        https://github.com/user/repo/issues
        http://www.github.com/user/repo/issues
        https://www.github.com/user/repo/tree
    ) )
    {
        normalize_issues_ok(
            bugtracker( web => $url ),
            { source => 'https://github.com/user/repo', active => 3 },
            { url    => $url,                           active => 3 },
            "github variation ($url) matches: specified url and count",
        );
    }

};

subtest 'normalize_notification_type' => sub {
    my @tests = (
        {
            params   => undef,
            expected => 0,
            message  => 'undef passed as params'
        },
        {
            params   => 'string',
            expected => 0,
            message  => 'string passed as params'
        },
        {
            params   => [qw/one two three/],
            expected => 0,
            message  => 'array passed as params'
        },
        {
            params   => {},
            expected => 0,
            message  => 'empty hash of data passed'
        },
        {
            params => {
                permission => {}
            },
            expected => 0,
            message  => 'empty permissions hash past'
        },
        {
            params => {
                permission => {
                    co_maintainers => [ 'ONE', 'TWO', 'THREE' ]
                }
            },
            expected => 0,
            message =>
                'co_maintainers passed without "special" co_maintainer existing'
        },
        {
            params => {
                permission => {
                    co_maintainers => [ 'ADOPTME', 'ONE', 'TWO', 'THREE' ]
                }
            },
            expected => 'ADOPTME',
            message  => 'ADOPTME passed in co_maintainers'
        },
        {
            params => {
                permission => {
                    co_maintainers => [ 'ONE', 'NEEDHELP', 'TWO', 'THREE' ]
                }
            },
            expected => 'NEEDHELP',
            message  => 'NEEDHELP passed in co_maintainers'
        },
        {
            params => {
                permission => {
                    owner          => 'LNATION',
                    co_maintainers => [ 'ONE', 'TWO', 'THREE', 'HANDOFF' ]
                }
            },
            expected => 'HANDOFF',
            message  => 'HANDOFF passed in co_maintainers'
        },
        {
            params => {
                permission => {
                    owner => ''
                }
            },
            expected => 0,
            message  => 'Null string as owner'
        },
        {
            params => {
                permission => {
                    owner => undef
                }
            },
            expected => 0,
            message  => 'Undef as owner'
        },
        {
            params => {
                permission => {
                    owner => 'LNATION'
                }
            },
            expected => 0,
            message  => 'LNATION as owner'
        },
        {
            params => {
                permission => {
                    owner => 'ADOPTME'
                }
            },
            expected => 'ADOPTME',
            message  => 'ADOPTME passed as owner'
        },
        {
            params => {
                permission => {
                    owner => 'HANDOFF'
                }
            },
            expected => 'HANDOFF',
            message  => 'HANDOFF passed as owner'
        },
        {
            params => {
                permission => {
                    owner => 'NEEDHELP'
                }
            },
            expected => 'NEEDHELP',
            message  => 'NEEDHELP passed as owner'
        },
    );

    for my $test (@tests) {
        is( $model->normalize_notification_type( $test->{params} ),
            $test->{expected}, $test->{message} );
    }
};

done_testing;
