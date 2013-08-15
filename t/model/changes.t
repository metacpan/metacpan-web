use strict;
use warnings;

use Test::More;
use aliased 'MetaCPAN::Web::Model::API::Changes';

subtest "RT ticket linking" => sub {

    my $u = "https://rt.cpan.org/Ticket/Display.html?id=";

    my %rt_tests = (
        'Fixed RT#1013'  => 'id=1013">RT#1013',
        'Fixed RT #1013' => 'id=1013">RT #1013',
        'Fixed RT-1013'  => 'id=1013">RT-1013',
        'Fixed #1013'    => 'id=1013"> #1013',
        'Fixed RT:1013'  => 'id=1013">RT:1013',
    );

    while (my ($in, $out) = each %rt_tests) {
        like(Changes->_rt_cpan($in), qr/$out/, "$in found");
    }
};

subtest "GH issue linking" => sub {
    my $u = 'https://github.com/CPAN-API/metacpan-web/issues/';
    my %gh_tests = (
        'Fixed #1013'    => 'issues/1013">#1013',
        'Fixed GH#1013'  => 'issues/1013">GH#1013',
        'Fixed GH-1013'  => 'issues/1013">GH-1013',
        'Fixed GH:1013'  => 'issues/1013">GH:1013',
        'Fixed GH #1013' => 'issues/1013">#1013',
    );
    while (my ($in, $out) = each %gh_tests) {
        like(Changes->_gh($in, $u), qr/$out/, "$in found");
    }
};



done_testing;
