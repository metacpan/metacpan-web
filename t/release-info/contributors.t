use strict;
use warnings;
use lib 't/lib';
use Test::More;
use TestReleaseInfo;

my $relinfo = TestReleaseInfo->new;
my $ctx     = $relinfo->_context;

sub groom_contributors {
    my ( $meta, $author ) = @_;

    # Author is used to de-dupe, but not actually added to contributors.
    $author ||= {
        pauseid      => 'LOCAL',
        name         => 'A CPAN Author',
        gravatar_url => '/gravatar/LOCAL',
        email        => ['local@example.com'],
    };
    $relinfo->groom_contributors(
        $ctx,

        # release object
        {
            author   => $author->{pauseid},
            metadata => $meta,
        },
        $author,
    );
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

done_testing;
