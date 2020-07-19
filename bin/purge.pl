#!/usr/bin/env perl

use strict;

# Purge stuff

=head1 NAME

  purge.pl

=head1 SYNOPSIS

  purge.pl --all
  purge.pl --key homepage --key about

=head1 DESCRIPTION

Script to purge things from Fastly CDN.

To clear a specific URL use:

  curl -X PURGE https://metacpan.org/XXXX

=cut

use File::Basename ();
use File::Spec     ();
use lib File::Spec->catdir( File::Basename::dirname(__FILE__),
    File::Spec->updir, 'lib' );
use MetaCPAN::Web;
use Getopt::Long::Descriptive;

my ( $opt, $usage ) = describe_options(
    'purge.pl %o',
    [ 'all',      "purge all", ],
    [ 'key|k=s@', "key(s) to purge", ],
    [ 'list|l',   'list available cache keys' ],
    [],
    [ 'help', "print usage message and exit" ],
);

print( $usage->text ), exit if $opt->help;

my $c = MetaCPAN::Web->new();

if ( $opt->all ) {
    $c->cdn_purge_all();

}
elsif ( $opt->list ) {
    ## no critic (MutatingList)
    print grep { !/_cache_key_for_user/ }
        map    { s/\A.+:\s+\$c->add_surrogate_key\((.+?)\);\Z/$1/; $_ }
        qx{git grep add_surrogate_key lib/MetaCPAN/Web/Controller/};
}
else {

    my $keys = $opt->key;

    $c->cdn_purge_now( {
        keys => $keys,
    } );

}
