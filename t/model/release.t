use strict;
use warnings;

use Test::More;
use Cpanel::JSON::XS qw( decode_json );
use MetaCPAN::Web ();

my ( $true, $false ) = @{ decode_json('[true, false]') };

# Explicitly test that we get a boolean.
# We use a work-around for older ES versions to ensure we get a bool
# and not a string (to ensure that conditions operate intuitively).
sub is_bool {
    my ( $got, $desc ) = @_;

    # Test that it is a boolean, but use "is" for better diagnostics.
    is( $got, ( $got ? $true : $false ), $desc );
}

subtest modules => sub {
    my @files
        = @{ MetaCPAN::Web->model('API::Release')
            ->modules( 'OALDERS', 'HTTP-CookieMonster-0.09' )->get->{modules}
        };

    ok( scalar @files, 'found files with modules' );

    foreach my $file (@files) {

        # this is a hack for the later sort check:
        # 1. fix to both 'undefined value' warnings
        # 2. make sure to push the empty values (undefined) to the end
        $file->{"documentation"} //= "Z" x 50;

        # Ensure we get a boolean so that conditions work as expected.
        is_bool( $file->{$_}, "'$_' is a boolean" )
            for qw( indexed authorized );
    }

    is_deeply [@files], [
        sort {
                   $a->{documentation} cmp $b->{documentation}
                or $a->{path} cmp $b->{path}
        } @files
        ],
        'files sorted by documentation name, then file path';
};

subtest versions => sub {

    # Something with not too many versions.
    my @versions
        = @{ MetaCPAN::Web->model('API::Release')
            ->versions('Mojolicious-Plugin-HamlRenderer')->get->{versions} };

    ok( scalar @versions, 'found release versions' );

    my %statuses;
    my @dates;
    foreach my $version (@versions) {

        # Ensure we get a boolean so that conditions work as expected.
        is_bool( $version->{authorized}, q['authorized' is a boolean] );

        ++$statuses{ $version->{status} };
        push @dates, $version->{date};
    }

    is( $statuses{latest}, 1, 'found one latest version' );
    is(
        $statuses{cpan} + ( $statuses{backpan} || 0 ),
        scalar(@versions) - 1,
        'other releases are cpan or backpan'
    );

    is_deeply [@dates], [ reverse sort @dates ], 'returned in date order';
};

done_testing;
