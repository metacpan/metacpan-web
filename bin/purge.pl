#!/usr/bin/env perl

use strict;

# Purge stuff

=head1 NAME

  purge.pl

=head1 SYNOPSIS

  purge.pl --all
  purge.pl --tag foo --tag bar
  purge.pl --url '/about/'

=head1 DESCRIPTION

Script to purge things from Fastly CDN.

=cut

use MetaCPAN::Web;
use Getopt::Long::Descriptive;
use List::MoreUtils qw(any);

my ( $opt, $usage ) = describe_options(
    'purge.pl %o <some-arg>',
    [ 'all=s',    "purge all", ],
    [ 'tag|t=s@', "tag(s) to purge", ],
    [ 'url|t=s@', "url(s) to purge", ],
    [],
    [ 'help', "print usage message and exit" ],
);

print( $usage->text ), exit if $opt->help;

my $c = MetaCPAN::Web->new();

if ( $opt->all ) {
    $c->cdn_purge_all();

}
else {

    my $tags = $opt->tag;
    my $urls = $opt->url;

    $c->cdn_purge_now(
        {
            tags => $tags,
            urls => $urls
        }
    );

}
