use strict;
use warnings;

use Test::More;
use JSON;
use MetaCPAN::Web;

sub search_release {
    my ( $method, @args ) = @_;
    return
        map { $_->{fields} } map { @{ $_->{hits}{hits} } }
        MetaCPAN::Web->model('API::Release')->$method(@args)->recv;
}

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
        = search_release( modules => 'OALDERS', 'HTTP-CookieMonster-0.07' );

    ok( scalar @files, 'found files with modules' );

    foreach my $file (@files) {

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


done_testing;
