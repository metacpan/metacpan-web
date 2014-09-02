use strict;
use warnings;

use Test::More;
use Perl::Critic;
use Test::Perl::Critic;

# NOTE: New files will be tested automatically.

# FIXME: Things should be removed (not added) to this list.
# Temporarily skip any files that existed before adding the tests.
# Eventually these should all be removed (once the files are cleaned up).
my %skip = map { ( $_ => 1 ) } qw(
    lib/MetaCPAN/Web/Controller/Author.pm
    lib/MetaCPAN/Web/Controller/Module.pm
    lib/MetaCPAN/Web/Controller/Pod.pm
    lib/MetaCPAN/Web/Controller/Recent.pm
    lib/MetaCPAN/Web/Controller/Release.pm
    lib/MetaCPAN/Web/Controller/Root.pm
    lib/MetaCPAN/Web/Controller/Search.pm
    lib/MetaCPAN/Web/Controller/Search/AutoComplete.pm
    lib/MetaCPAN/Web/Controller/Source.pm
    lib/MetaCPAN/Web/Model/API.pm
    lib/MetaCPAN/Web/Model/API/Changes/Parser.pm
    lib/MetaCPAN/Web/Model/API/Diff.pm
    lib/MetaCPAN/Web/Model/API/File.pm
    lib/MetaCPAN/Web/Test.pm
    lib/MetaCPAN/Web/View/HTML.pm
    lib/Plack/Middleware/MCLess.pm
    t/encoding.t
    t/fastly_headers.t
    t/controller/author.t
    t/controller/changes.t
    t/controller/home.t
    t/controller/pod.t
    t/controller/raw.t
    t/controller/recent.t
    t/controller/release.t
    t/controller/search.t
    t/controller/source.t
    t/metacpan/sitemap.t
    t/model/changes.t
    t/plack/mcless.t
    t/controller/favorite/leaderboard.t
    t/controller/search/autocomplete.t
    t/controller/search/suggestion.t
    t/model/changes-tests/read_dbix-class.t
    t/model/changes-tests/read_moose.t
);

my @files = grep { !$skip{$_} }
    ( 'app.psgi', Perl::Critic::Utils::all_perl_files(qw( bin lib t )) );

foreach my $file (@files) {
    critic_ok( $file, $file );
}

done_testing();
