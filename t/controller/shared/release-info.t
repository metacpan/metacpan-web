use strict;
use warnings;
use Test::More;
use MetaCPAN::Web::Test;

# Test various aspects that should be similar
# among controllers that show release info (in the side bar).
# Currently this includes module and release controllers

test_psgi app, sub {
    my $cb = shift;
    my @tests = (
        { module => 'Moose' },
    );

foreach my $test ( @tests ) {
    ($test->{release} = $test->{module}) =~ s/::/-/g
        if !$test->{release};

    # short cuts
    my ($module, $release) = @{$test}{qw(module release)};
    my $first_letter = uc(substr($release, 0, 1));

    foreach my $controller ( qw(module release) ) {
        my $name = $test->{ $controller };

        my $req_uri = "/$controller/$name";
        ok( my $res = $cb->( GET $req_uri ), "GET $req_uri" );
        is( $res->code, 200, 'code 200' );
        my $tx = tx($res);

        # these first tests are similar between the controllers only because of
        # consistecy or coincidence and are not specifically related to release-info
        $tx->like( '/html/head/title', qr/$name/, qq["title includes name "$name"] );

        ok( $tx->find_value(qq<//a[\@href="/$controller/$name"]>),
            'contains permalink to resource'
        );

        ok( my $this = $tx->find_value('//a[text()="This version"]/@href'),
            'contains link to "this" version' );

        # A fragile and unsure way to get the version, but at least an 80% solution.
        # TODO: Set up a fake cpan; We'll know what version to expect; we can test that this matches
        ok( my $version = ($this =~ m!/$controller/[^/]+/$release-([^/"]+)!)[0], 'got version from "this" link' );

        # TODO: latest version (should be where we already are)

        # Info about a release (either the one we're looking at or the one the module belongs to)

        # TODO: Download
        # TODO: Changes

        # TODO: Moose doesn't have a homepage, we need to test a dist that does (better yet test against a fake cpan)
        # TODO: what is <li>release.resources</li> supposed to be?

        ok(  $tx->find_value('//a[text()="Repository"]/@href'),
            'link for resources.repository.web' );

        # both web and url keys
        ok(  $tx->find_value('//a[text()="git clone"]/@href'),
            'link for resources.repository.url' );

        # we could test the rt.cpan.org link... i think others are verbatim from the META file
        ok(  $tx->find_value('//a[text()="Bugs"]/@href'),
            'link for bug tracker' );

        # Moose has ratings, but not all dists do (so be careful what we're testing with)
        my $reviews = '//div[@class="search-bar"]//div[starts-with(@class, "rating-")]/following-sibling::a';
        $tx->is(
            "$reviews/\@href",
            "http://cpanratings.perl.org/dist/$release",
            'link to current reviews'
        );
        $tx->like(
            $reviews,
            qr/\d+ reviews?/i,
            'current rating and number of reviews listed'
        );

        # all dists should get a link to rate it; test built url
        $tx->is(
            '//div[@class="search-bar"]//a[text()="Rate this distribution"]/@href',
            "http://cpanratings.perl.org/rate/?distribution=$release",
            'cpanratings link to rate this dist'
        );

        # test format of cpantesters link
        $tx->is(
            '//a[text()="Test results"]/@href',
            "http://www.cpantesters.org/distro/$first_letter/$release.html#$release-$version",
            'link to test results'
        );

        # TODO: release.tests.size

        $tx->is(
            '//a[@title="Matrix"]/@href',
            "http://matrix.cpantesters.org/?dist=$release-$version",
            'link to test matrix'
        );

        # version select box
        ok( $tx->find_value('//select[@name="release"]/option[text()="Go to version"]'),
          'version select box' );

        $tx->like(
            # "go to" option has no value attr
            '//select[@name="release"]/option[@value][1]',
            qr/\(\d{4}-\d{2}-\d{2}\)$/,
            'version ends with date in common format'
        );

        # TODO: diff with version
        # TODO: search
# TODO: toggle table of contents (module only)
        # TODO: reverse deps
        # TODO: explorer
        # TODO: activity
    }
}

};

# TODO ok( $found_ratings, "at least one module had ratings" );

done_testing;
