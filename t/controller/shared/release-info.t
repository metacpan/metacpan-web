use strict;
use warnings;
use Test::More 0.96;
use MetaCPAN::Web::Test qw( app GET test_psgi tx );

use Module::Runtime qw( use_module );

my $model     = use_module('MetaCPAN::Web::Model::ReleaseInfo');
my $rt_prefix = $model->rt_url_prefix;

# Test various aspects that should be similar
# among controllers that show release info (in the side bar).
# Currently this includes module and release controllers.

# Not all tests apply to all releases.
my @optional = qw(
    favorited
    home_page
    repository
    issues
);

# Use a counter to make sure we at least do each optional test once.
my %tested = map { ( $_ => 0 ) } @optional;

# global var (eww) used for test names
my $current;

sub optional_test;    # predeclare for non-parenthetical usage below

test_psgi app, sub {
    my $cb = shift;

    # Tests default to true unless explicitly set to false.
    # Setting to false does not test for failure, it simply skips the test.

    my @tests = (

        # has all optional tests
        {
            module => 'Dist::Zilla',
            issues => 'https://github.com/rjbs/Dist-Zilla/issues'
        },

        # dist name that needs uri encoding
        {
            module     => 'Text::Tabs',
            release    => 'Text-Tabs+Wrap',
            qs_dist    => 'Text-Tabs%2BWrap',
            home_page  => 0,
            repository => 0,
            reviews    => 0,
        },

        # release name different than just s/::/-/g
        {
            module     => 'LWP::UserAgent',
            release    => 'libwww-perl',
            repository => 0,
            home_page  => 0,
            issues     => 'https://github.com/libwww-perl/libwww-perl/issues',
        },

        # no optional tests
        {
            module     => 'CGI::Bus',
            home_page  => 0,
            reviews    => 0,
            repository => 0,
            favorited  => 0
        },
    );

    foreach my $test (@tests) {
        ( $test->{release} = $test->{module} ) =~ s/::/-/g
            if !$test->{release};
        my $qs_dist   = $test->{qs_dist} || $test->{release};
        my $qs_module = $test->{module};

        # turn tests on by default
        $test->{issues} //= $rt_prefix . $qs_dist;
        exists( $test->{$_} ) or $test->{$_} = 1 for @optional;

        # short cuts
        my ( $module, $release ) = @{$test}{qw(module release)};
        my $first_letter = uc( substr( $release, 0, 1 ) );

        foreach my $type (qw(module release)) {
            my $name = $test->{$type};
            $current = { desc => "$type $name", test => $test };

            my $req_uri = $type eq 'module' ? "/pod/$name" : "/dist/$name";

            ok( my $res = $cb->( GET $req_uri ), "GET $req_uri" );
            is( $res->code, 200, 'code 200' );
            my $tx = tx($res);

  # these first tests are similar between the controllers only because of
  # consistecy or coincidence and are not specifically related to release-info
            $tx->like( '/html/head/title', qr/\Q$name\E/,
                qq[title includes name "$name"] );

            ok( $tx->find_value(qq<//a[\@href="$req_uri"]>),
                'contains permalink to resource' );

            ok(
                my $this = $tx->find_value(
                    '//a[text()="This version"][starts-with(@href,"/")]/@href'
                ),
                'contains link to "this" version'
            );

# A fragile and unsure way to get the version, but at least an 80% solution.
# TODO: Set up a fake cpan; We'll know what version to expect; we can test that this matches
            ok(
                my $version = (
                    $this =~ m!(?:/pod)?/release/[^/]+/\Q$release\E-([^/"]+)!
                )[0],
                'got version from "this" link'
            );

            my $qs_version = $version;

            # TODO: latest version (should be where we already are)
            # TODO: author

            # not in release-info.html but should be shown on both:

            my $favs = '//*[contains(@class, "favorite")]';
            $tx->like( $favs, qr/\+\+$/, 'tag for favorites (++)' );

            optional_test favorited => sub {
                ok(
                    $tx->find_value("$favs/span") > 0,
                    "$req_uri has been marked as favorite"
                );
            };

# Info about a release (either the one we're looking at or the one the module belongs to)

            # TODO: Download
            # TODO: Changes

            optional_test home_page => sub {
                ok( $tx->find_value('//a[text()="Homepage"]/@href'),
                    'link for resources.homepage' );
            };

            # test separate links for both web and url keys (if specified)
            optional_test repository => sub {
                ok( $tx->find_value('//a[text()="Repository"]/@href'),
                    'link for resources.repository.web' );

                ok( $tx->find_value('//a[text()="git clone"]/@href'),
                    'link for resources.repository.url' );
            };

            optional_test issues => sub {
                $tx->is( '//a[text()="Issues"]/@href', $test->{issues},
                    'link to bug tracker' );
            };

            # TODO: cpantesters
            # TODO: release.tests.size

            $tx->is(
                '//a[@title="Matrix"]/@href',
                "http://matrix.cpantesters.org/?dist=$qs_dist+$qs_version",
                'link to test matrix'
            );

            # version select box
            ok( $tx->find_value('//div[@class="breadcrumbs"]//select'),
                'version select box' );

            $tx->like(

                # "go to" option has no value attr
                q[//*[contains-token(@class, 'version-jump')]//select/option[@value][1]],
                qr/\([A-Z]{3,9} on \d{4}-\d{2}-\d{2}\)$/,
                'version ends with pause id and date  in common format'
            );

            # TODO: diff with version
            # TODO: search
            # TODO: toggle table of contents (module only)

            my $revdep = $type eq 'module' ? 'module' : 'dist';
            ok(
                $tx->find_value(
                    "//a[starts-with(\@href, \"/$revdep/$name/requires\")]"),
                "reverse deps link uses $revdep name"
            );

            $tx->like(
                '//a[starts-with(@href, "https://explorer.metacpan.org/?url")]/@href',
                $type eq 'module'
                ? qr!\?url=%2Fmodule%2F\w+%2F${qs_dist}-${version}%2F.+!
                : qr!\?url=%2Frelease%2F\w+%2F${qs_dist}-${version}\z!,
                'explorer link points to module file or release',
            );

            # TODO: activity
        }
    }

    ok( $tested{$_} > 0, "at least one module tested $_" )
        for sort keys %tested;

};

done_testing;

sub optional_test {
    my ( $name, $sub ) = @_;
    subtest $name => sub {
        plan skip_all => "$name test for $current->{desc}"
            unless $current->{test}->{$name};
        $sub->();
        ++$tested{$name};
    };
}
