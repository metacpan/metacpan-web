use strict;
use warnings;

use Test::More;

eval q{
    use Path::Iterator::Rule;
    use Path::Tiny qw(path);
};
plan skip_all => 'Path::Iterator::Rule and Path::Tiny are needed for this test' if $@;

# files that have inline <script> tags
my %skip = map { $_ => 1 }
	'root/account/profile.html',
	'root/account/turing.html',
	'root/inc/dependencies-graph.html',
	'root/recent/log.html';

my $rule = Path::Iterator::Rule->new;
$rule->name("*.html");
for my $file ( $rule->all( 'root' ) ) {
    my $html = path($file)->slurp_utf8;
	ok $html !~ /<style>/, "no inline style in $file";
	if (not $skip{$file}) {
		ok $html !~ /<script>/, "no inline script in $file";
	}
}

done_testing;

