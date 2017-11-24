use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

test_psgi app, sub {
    my $cb = shift;
    ok( my $res = $cb->( GET '/release/DOESNTEXIST' ),
        'GET /release/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET '/release/AUTHORDOESNTEXIST/DOESNTEXIST' ),
        'GET /release/AUTHORDOESNTEXIST/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET '/release/PERLER/DOESNTEXIST' ),
        'GET /release/PERLER/DOESNTEXIST' );
    is( $res->code, 404, 'code 404' );

    ok( $res = $cb->( GET '/release/Moose' ), 'GET /release/Moose' );
    is( $res->code, 200, 'code 200' );

    my $tx = tx($res);
    $tx->like( '/html/head/title', qr/Moose/, 'title includes Moose' );
    ok( $tx->find_value('//a[@href="/release/Moose"]'),
        'contains permalink to resource' );

    # Moose 2.1201 has no more Examples and breaks this test,
    # so pin to an older version for now.
    test_heading_order( $cb->( GET '/release/ETHER/Moose-2.1005' ) );

    ok( $tx->find_value('//div[contains(@class, "plussers")]'),
        'has plussers' );

   # Return @href as value b/c there is no child text content (it's an image).
    ok(
        $tx->find_value(
            '//div[contains(@class, "plussers")]//a[contains(@href, "/author/")]/@href'
        ),
        'has cpan author plussers'
    );

# FIXME: This xpath garbage is getting out of hand.  Semantic HTML would help a lot.
# '//li[text()="Permalinks"]/following-sibling::li/a[text()="This version" and not(@rel="nofollow")]/@href'
    ok(
        my $this = $tx->find_value(
            '//li[text()="Permalinks"]/following-sibling::li[a[text()="This version"]][1]/a[text()="This version"]/@href'
        ),
        'contains link to "this" version'
    );
    my $latest = $tx->find_value('//div[@class="content"]');
    ok( $res = $cb->( GET $this ), "GET $this" );
    my $tx_latest = tx($res);
    is(
        $latest,
        $tx_latest->find_value('//div[@class="content"]'),
        'content of both urls is exactly the same'
    );

    # get module with lc author
    $this =~ s{(/release/.*?/)}{lc($1)}e;    # lc author name
    ok( $res = $cb->( GET $this ), "GET $this" );
    is( $res->code, 301, 'code 301' );

    ok( $res = $cb->( GET '/release/BRICAS/CPAN-Changes-0.21' ),
        'GET /release/BRICAS/CPAN-Changes-0.21' );
    is( $res->code, 200, 'code 200' );
    my $tx_cc = tx($res);
    is(
        $tx_cc->find_value(
            '//a[@href="https://rt.cpan.org/Ticket/Display.html?id=84994"]'),
        'RT #84994',
        'Link to rt is there'
    );

    ok( $res = $cb->( GET '/release/ANDREMAR/WWW-Curl-Simple-0.100187' ) );
    $tx_cc = tx($res);
    is(
        $tx_cc->find_value(
            '//a[@href="https://github.com/omega/www-curl-simple/issues/8"]'),
        '#8',
        'link to github issues is there'
    );

    # Test that we don't show changes for unrelated version, check issue #914
    # for original bug report.
    ok( $res = $cb->( GET '/release/SHLOMIF/Config-IniFiles-2.43/' ) );
    $tx_cc = tx($res);
    $tx_cc->not_ok(
        '//div[@class="content"]/strong[following-sibling::div[@class="last-changes"]]'
    );
    is(
        $tx_cc->find_value(
            '//a[@href="https://search.cpan.org/~SHLOMIF/Config-IniFiles-2.43/" and @rel="nofollow"]'
        ),
        'This version',
        'Link to release search.cpan.org of this version is correct'
    );
    is(
        $tx_cc->find_value(
            '//a[@href="https://search.cpan.org/dist/Config-IniFiles" and @rel="nofollow"]'
        ),
        'Latest version',
        'Link to release search.cpan.org of the latest version is correct'
    );

    ok(
        $res = $cb->(
            GET
                '/pod/release/SHLOMIF/Config-IniFiles-2.83/lib/Config/IniFiles.pm'
        )
    );
    $tx_cc = tx($res);
    is(
        $tx_cc->find_value(
            '//a[@href="https://search.cpan.org/~SHLOMIF/Config-IniFiles-2.83/lib/Config/IniFiles.pm" and @rel="nofollow"]'
        ),
        'This version',
        'Link to module search.cpan.org of this version is correct'
    );
    is(
        $tx_cc->find_value(
            '//a[@href="https://search.cpan.org/perldoc?Config::IniFiles" and @rel="nofollow"]'
        ),
        'Latest version',
        'Link to module search.cpan.org of the latest version is correct'
    );
};

my $rt      = 'https://rt.cpan.org/Ticket/Display.html?id=';
my $rt_perl = 'https://rt.perl.org/Ticket/Display.html?id=';
my $gh      = 'https://github.com/metacpan/metacpan-web/issues/';

subtest 'RT ticket linking' => sub {
    my %rt_tests = (
        'Fixed RT#1013'  => 'id=1013">RT#1013',
        'Fixed RT #1013' => 'id=1013">RT #1013',
        'Fixed RT-1013'  => 'id=1013">RT-1013',

        # This one is too broad for now?, see ticker #914
        # 'Fixed #1013'    => 'id=1013"> #1013',
        'Fixed RT:1013' => 'id=1013">RT:1013',

        # We don't want to link the time in this one..
        # See ticket #914
        'Revision 2.15 2001/01/30 11:46:48 rbowen' =>
            'Revision 2.15 2001/01/30 11:46:48 rbowen',
        'Fix bad parsing of HH:mm:ss -> 24:00:00, rt87550 (reported by Gonzalo Mateo)'
            => 'id=87550">rt87550',
        'Fix bug #87801 where excluded tags were ANDed instead of ORed. Stefan Corneliu Petrea.'
            => 'id=87801">bug #87801',
        'Blah blah [rt.cpan.org #231] fixed' =>
            'id=231">rt.cpan.org #231</a>',
        'Blah blah rt.cpan.org #231 fixed' => 'id=231">rt.cpan.org #231</a>',
        'See P5#72210 ' => "${rt_perl}72210\">P5#72210</a>",
    );

    while ( my ( $in, $out ) = each %rt_tests ) {
        like(
            MetaCPAN::Web::Controller::Release::_link_issue_text(
                $in, $gh, $rt
            ),
            qr/\Q$out\E/,
            "$in found"
        );
    }
};

subtest 'GH issue linking' => sub {
    my %gh_tests = (
        'Fixed #1013'                             => 'issues/1013">#1013',
        'Fixed GH#1013'                           => 'issues/1013">GH#1013',
        'Fixed GH-1013'                           => 'issues/1013">GH-1013',
        'Fixed GH:1013'                           => 'issues/1013">GH:1013',
        'Fixed GH #1013'                          => 'issues/1013">GH #1013',
        'Add HTTP logger (gh-16; thanks djzort!)' => 'issues/16">gh-16',
        'Merged PR#1013 -- thanks' => 'issues/1013">PR#1013</a>',
        'Merged PR:1013 -- thanks' => 'issues/1013">PR:1013</a>',
        'Merged PR-1013 -- thanks' => 'issues/1013">PR-1013</a>',
    );
    while ( my ( $in, $out ) = each %gh_tests ) {
        like(
            MetaCPAN::Web::Controller::Release::_link_issue_text(
                $in, $gh, $rt
            ),
            qr/\Q$out\E/,
            "$in found"
        );
    }
    my @no_links_tests
        = ('I wash my hands of this library forever -- rjbs, 2013-10-15');
    foreach my $in (@no_links_tests) {
        is(
            MetaCPAN::Web::Controller::Release::_link_issue_text(
                $in, $gh, $rt
            ),
            $in,
            "Didn't change '$in'"
        );
    }
};

done_testing;

sub test_heading_order {
    my ( $res, $desc ) = @_;
    ok( $res, $desc || 'found' );
    my $tx = tx($res);

    # Figure out version for Changes test
    my ( undef, undef, $author, $module ) = split m|/|,
        $tx->find_value('//a[text()="This version"]/@href');
    $module =~ s/[^\d\w_.-]//g;
    my ($version) = ( reverse split /-/, $module );

    # Confirm that the headings in the content div are in the expected order.
    my @headings = ( 'Documentation', 'Modules', 'Provides', 'Examples',
        'Other files', );
    my @anchors = qw(docs modules provides examples other whatsnew);
    push @headings, 'Changes for version ' . $version;
    my $heading = 0;

    # Boohoo... testing with XPATH :-(
    my $xpath_prefix
        = '//div[@class="content"]/div[contains(@class, "file-group")]';
    $tx->ok(
        "$xpath_prefix/h2",
        sub {
            $_->is( q{.}, $headings[$heading],
                "heading $headings[$heading] in expected location" );
            $heading++;
        },
        'headings in correct order'
    );

    my $anchor = 0;
    $tx->ok(
        "$xpath_prefix/h2",
        sub {
            $_->is( './@id', $anchors[$anchor],
                "Anchor $anchors[$anchor] in expected location" );
            $anchor++;
        },
        'anchors are correct.'
    );
}
