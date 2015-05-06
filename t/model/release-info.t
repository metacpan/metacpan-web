use strict;
use warnings;

use lib 't/lib';
use Test::More;
use TestContext qw( get_context );
use Module::Runtime qw( use_module );

my $model = use_module('MetaCPAN::Web::Model::ReleaseInfo');
my $ctx   = get_context();

sub release_info {
    $model->new( c => $ctx, @_ );
}

sub groom_contributors {
    my ( $meta, $author ) = @_;

    # Author is used to de-dupe, but not actually added to contributors.
    $author ||= {
        pauseid      => 'LOCAL',
        name         => 'A CPAN Author',
        gravatar_url => '/gravatar/LOCAL',
        email        => ['local@example.com'],
    };
    release_info(

        # release object
        release => {
            author   => $author->{pauseid},
            metadata => $meta,
        },
        author => $author,
    )->groom_contributors;
}

subtest contributors => sub {
    my $uri_prefix = 'http://localhost';
    my $xy_string  = 'X <y@cpan.org>';
    my $xy_parsed  = {
        name    => 'X',
        email   => [ 'y@cpan.org', ],
        pauseid => 'Y',
        url     => "$uri_prefix/author/Y",
    };

    is_deeply(
        groom_contributors(
            {
                x_contributors => [ 'Just A Name', 'A <b@c.d>', $xy_string, ],
            }
        ),
        [
            {
                name  => 'Just A Name',
                email => [],
            },
            {
                name  => 'A',
                email => ['b@c.d'],
            },
            $xy_parsed,
        ],
        'parse array of contributor strings'
    );

    is_deeply(
        groom_contributors(
            {
                x_contributors => $xy_string,
            }
        ),
        [ $xy_parsed, ],
        'groom single contributor string (not array)'
    );

    is_deeply(
        groom_contributors(
            {
                x_contributors => [
                    $xy_string,
                    'person <local@cpan.org>',              # releaser pauseid
                    'person <local@example.com>',           # releaser email
                    'A CPAN Author <local@example.org>',    # releaser name
                    'A. Nother <another@example.com>',
                    'Hello <again@example.com>',
                ],
                author => [ 'Hello <there@example.com>', ],
            }
        ),
        [
            {
                email => [ 'there@example.com', 'again@example.com' ],
                name  => 'Hello',
            },
            $xy_parsed,
            {
                email => ['another@example.com'],
                name  => 'A. Nother',
            }
        ],
        'releaser removed from contributors by name and email'
    );

    is_deeply(
        groom_contributors(
            {
                x_contributors => $xy_string,
                author         => 'unknown',
            }
        ),
        [ $xy_parsed, ],
        'unknown author left out'
    );

    is_deeply(
        groom_contributors(
            {
                x_contributors => { 'A <b@c.d>', 'X <y@cpan.org>', }
            }
        ),
        [],
        'groom_contributors returns none but does not die with hashref'
    );
};

my $rt_prefix = $model->rt_url_prefix;

sub bugtracker {
    return { resources => { bugtracker => {@_} } };
}

sub normalize_issues_ok {
    my ( $release, $bugs, $exp, $desc ) = @_;
    my $instance = $model->new(
        {
            release => { distribution => 'X', %$release },
            distribution =>

                # Default to rt url, but let data override.
                { bugs => { source => "${rt_prefix}X", %$bugs } },
        }
    );
    is_deeply $instance->normalize_issues, $exp, $desc;
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
    foreach my $url (
        qw(
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
        )
        )
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

};

done_testing;
