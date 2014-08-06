use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;
use Try::Tiny;
use MetaCPAN::Web::Controller::Feed;

my @tests
    = qw(/feed/recent /feed/author/PERLER /feed/distribution/Moose /feed/news);

test_psgi app, sub {
    my $cb = shift;
    foreach my $test (@tests) {
        subtest $test => sub {
            ok( my $res = $cb->( GET $test), $test );
            is( $res->code, 200, 'code 200' );
            is(
                $res->header('content-type'),
                'application/rss+xml; charset=UTF-8',
                'Content-type is application/rss+xml'
            );

            my $tx = valid_xml( $res, $test );
        };
    }

    test_redirect( $cb, 'oalders' );
};

sub test_redirect {
    my ( $cb, $author ) = @_;
    ok( my $redir = $cb->( GET "/feed/author/\L$author" ), 'lc author feed' );
    is( $redir->code, 301, 'permanent redirect' );

    # Ignore scheme and host, just check that uri path is what we expect.
    like(
        $redir->header('location'),
        qr{^(\w+://[^/]+)?/feed/author/\U$author},
        'redirect to uc feed'
    );
}

sub valid_xml {
    my ($res) = @_;
    my ( $tx, $err );

    try { $tx = tx($res) } catch { $err = $_[0] };

    ok( $tx, 'valid xml' );
    is( $err, undef, 'no errors' )
        or diag Test::More::explain $res;

    return $tx;
}

subtest 'get correct author entry data format' => sub {
    my $feed = MetaCPAN::Web::Controller::Feed->new();
    my $data = [
        {
            abstract     => "A brand new module from PERLHACKER",
            author       => "PERLHACKER",
            date         => "2012-12-12T05:17:44.000Z",
            distribution => "Some-New-Module",
            name         => "Some-New-Module-0.001",
            status       => "latest",
        },
        {
            author       => "ABIGAIL",
            date         => "2014-01-16T21:51:00.000Z",
            distribution => "perl",
        }
    ];
    my $entry = $feed->build_author_entry( 'PERLHACKER', $data );
    is(
        $entry->[0]->{abstract},
        'A brand new module from PERLHACKER',
        'get correct release abstract'
    );
    is(
        $entry->[0]->{link},
        'https://metacpan.org/release/PERLHACKER/Some-New-Module-0.001',
        'get correct release link'
    );
    is(
        $entry->[0]->{name},
        'PERLHACKER has released Some-New-Module-0.001',
        'get correct release title'
    );
    is( $entry->[0]->{author}, 'PERLHACKER', 'get correct author name' );
    is(
        $entry->[1]->{abstract},
        'PERLHACKER ++ed perl from ABIGAIL',
        'get correct favorite abstract'
    );
    is(
        $entry->[1]->{link},
        'https://metacpan.org/pod/perl',
        'get correct link to ++ed module'
    );
    is(
        $entry->[1]->{name},
        'PERLHACKER ++ed perl',
        'get correct ++ed title'
    );
    is( $entry->[1]->{author},
        'PERLHACKER', 'author on feed should be who ++' );
};
done_testing;
