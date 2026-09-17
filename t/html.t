use strict;
use warnings;
use lib 't/lib';

use Test::More;

use File::Find ();
use Path::Tiny qw( path );

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

            my $html = path($file)->slurp_utf8;

            ok $html !~ /<style>/, "no inline style in $file";

            my @script_tags = $html =~ /<script\b([^>]*)>/g;
            my @inline_js   = grep {

                # src scripts are external, never inline
                /\bsrc=/            ? 0
                    : /\btype="([^"]*)"/
                    ? ( $1 =~ /(?:j|java|emca)script/ ? 1 : 0 )
                    : 1;
            } @script_tags;
            ok !@inline_js, "no inline script in $file";
        },
    },
    'root'
);

done_testing;
