use strict;
use warnings;

use Test::More;
use aliased 'CPAN::Changes::Release';

use aliased 'MetaCPAN::Web::Model::API::Changes';

subtest "RT ticket linking" => sub {

    my $u = "https://rt.cpan.org/Ticket/Display.html?id=";

    my %rt_tests = (
        'Fixed RT#1013'  => 'id=1013">RT#1013',
        'Fixed RT #1013' => 'id=1013">RT #1013',
        'Fixed RT-1013'  => 'id=1013">RT-1013',
        # This one is too broad for now?, see ticker #914
        # 'Fixed #1013'    => 'id=1013"> #1013',
        'Fixed RT:1013'  => 'id=1013">RT:1013',
        # We don't want to link the time in this one..
        # See ticket #914
        'Revision 2.15 2001/01/30 11:46:48 rbowen' => 'Revision 2.15 2001/01/30 11:46:48 rbowen',
        'Fix bad parsing of HH:mm:ss -> 24:00:00, rt87550 (reported by Gonzalo Mateo)' =>
        'id=87550">rt87550',
        'Fix bug #87801 where excluded tags were ANDed instead of ORed. Stefan Corneliu Petrea.' =>
        'id=87801">bug #87801',
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
        'Add HTTP logger (gh-16; thanks djzort!)' => 'issues/16">gh-16',
    );
    while (my ($in, $out) = each %gh_tests) {
        like(Changes->_gh($in, $u), qr/$out/, "$in found");
    }
};

subtest 'find changelog' => sub {
    my $releases = [
        Release->new(version => 0.01),
        Release->new(version => 12314),
    ];

    my $latest = Changes->find_changelog(0.01, $releases);
    is($latest->version, "0.01", "found the version we wanted..");

};


done_testing;
