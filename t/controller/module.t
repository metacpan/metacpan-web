use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET "/module/DOESNTEXIST" ),
        'GET /module/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET "/module/Moose" ), 'GET /module/Moose' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose/, 'title includes Moose' );
    ok( $tx->find_value('//a[@href="/module/Moose"]'),
        'contains permalink to resource'
    );
    ok( my $this = $tx->find_value('//a[text()="This version"]/@href'),
        'contains link to "this" version' );
    my $latest = $res->content;
    ok( $res = $cb->( GET $this ), "GET $this" );
    is($latest, $res->content, 'content of both urls is exactly the same');
    # only 1 link to rev deps b/c this module == main_module
    check_rev_deps($tx, qw(Moose));

    # get module with lc author
    $this =~ s{(/module/.*?/)}{lc($1)}e; # lc author name
    ok( $res = $cb->( GET $this ), "GET $this" );
    is( $res->code, 301, 'code 301' );

    # check reverse deps link for a module that isn't the dist's main_module
    ok( $res = $cb->( GET "/module/Moose::Role" ), 'GET /module/Moose::Role' );
    is( $res->code, 200, 'code 200' );
    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose::Role/, 'title includes Moose::Role' );

    check_rev_deps($tx, qw(Moose::Role Moose));
};

done_testing;

sub check_rev_deps {
    my ($tx, @revdeps) = @_;
    $tx->ok( '//ul[@class="rev-deps"]/li/a', sub {
        my $rdep = shift @revdeps;
        shift->is( '.', $rdep, "Reverse deps for $rdep");
    }, 'Should have reverse dependency links' );
    is scalar @revdeps, 0, 'all rev deps found';
}
