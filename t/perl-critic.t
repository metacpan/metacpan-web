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
    lib/MetaCPAN/Web/Controller/Pod.pm
    lib/MetaCPAN/Web/Controller/Release.pm
    lib/MetaCPAN/Web/Model/API.pm
    lib/MetaCPAN/Web/Test.pm
    t/encoding.t
    t/controller/changes.t
    t/controller/home.t
    t/controller/pod.t
    t/controller/raw.t
    t/metacpan/sitemap.t
);

my @files = grep { !$skip{$_} }
    ( 'app.psgi', Perl::Critic::Utils::all_perl_files(qw( bin lib t )) );

foreach my $file (@files) {
    critic_ok( $file, $file );
}

done_testing();
