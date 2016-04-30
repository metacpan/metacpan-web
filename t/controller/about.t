use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

my @tests = (
    {
        url => '/about'
    },
    {
        url => '/about/contact',
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
                surrogate_control => 'max-age=31536000',
            }
        );
    }

};

done_testing;
