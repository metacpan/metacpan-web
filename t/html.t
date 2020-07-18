use strict;
use warnings;

use Test::More;

use File::Find ();
use Path::Tiny qw( path );

# files that have inline <script> tags
my %skip = map { $_ => 1 } (
    'root/about/contributors.tx', 'root/account/profile.tx',
    'root/account/turing.tx',     'root/base.tx',
);

File::Find::find(
    {
        no_chdir => 1,
        wanted   => sub {
            my $file = $File::Find::name;
            if ( $file eq 'root/static' ) {
                $File::Find::prune = 1;
                return;
            }
            elsif ( -d $file ) {
                return;
            }
            elsif ( $file !~ /\.tx\z/ ) {
                return;
            }
            elsif ( $skip{$file} ) {
                return;
            }

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
        },
    },
    'root'
);

done_testing;
