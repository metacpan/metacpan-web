use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;
use Try::Tiny;

my @tests = qw(/feed/recent /feed/author/PERLER /feed/distribution/Moose);

test_psgi app, sub {
    my $cb = shift;
    foreach my $test (@tests) {
      subtest $test => sub {
        ok( my $res = $cb->( GET $test), $test );
        is( $res->code, 200, 'code 200' );
        is( $res->header('content-type'),
            'application/rss+xml; charset=UTF-8', 'Content-type is application/rss+xml' );

        my $tx = valid_xml($res, $test);
      };
    }
};

sub valid_xml {
    my ($res) = @_;
    my ($tx, $err);

    try { $tx = tx($res) }
    catch { $err = $_[0] };

    ok( $tx, 'valid xml' );
    is($err, undef, 'no errors');

    return $tx;
}

done_testing;
