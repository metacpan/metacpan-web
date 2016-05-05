use strict;
use warnings;

use Test::More;

use Path::Iterator::Rule;
use Path::Tiny qw(path);

# files that have inline <script> tags
my %skip = map { $_ => 1 } (
    'root/account/profile.html',        'root/account/turing.html',
    'root/inc/dependencies-graph.html', 'root/author.html',
    'root/mirrors.html',                'root/source.html',
    'root/wrapper.html',                'root/about/contributors.html',
    'root/inc/favorite.html',           'root/about/stats.html',
);

my $rule = Path::Iterator::Rule->new;
$rule->name('*.html');
for my $file ( $rule->all('root') ) {
    my $html = path($file)->slurp_utf8;
    ok $html !~ /<style>/, "no inline style in $file";
    if ( not $skip{$file} ) {
        ok $html !~ /<script[>\s]/, "no inline script in $file";
    }
}

done_testing;
