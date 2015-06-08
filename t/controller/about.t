use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

my @tests = (
    {
        url => '/about'
    },
    {
        url => '/about/resources',
    },
);

test_psgi app, sub {
    my $cb = shift;

    foreach my $test (@tests) {
        ok( my $res = $cb->( GET $test->{url} ), 'GET ' . $test->{url} );
        is( $res->code, 200, 'code 200' );
        test_cache_headers(
            $res,
            {
                cache_control     => 'max-age=86400',
                surrogate_key     => 'about',
                surrogate_control => 'max-age=86400',
            }
        );
    }

};

done_testing;
