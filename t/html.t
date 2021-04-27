use strict;
use warnings;

use Test::More;

use Path::Iterator::Rule;
use Path::Tiny qw( path );

# files that have inline <script> tags
my %skip = map { $_ => 1 } (
    'root/about/contributors.html', 'root/account/profile.html',
    'root/account/turing.html',     'root/wrapper.html',
);

my $rule = Path::Iterator::Rule->new;
$rule->name('*.html');
for my $file ( $rule->all('root') ) {
    my $html = path($file)->slurp_utf8;
    ok $html !~ /<style>/, "no inline style in $file";
    if ( not $skip{$file} ) {
        my @script_tags = $html =~ /<script\b([^>]*)>/;
        my @js          = grep {
            /\btype="([^"]*)"/
                ? ( $1 =~ /(?:j|java|emca)script/ ? 1 : () )
                : 1
        } @script_tags;
        ok !@js, "no inline script in $file";
    }
}

done_testing;
