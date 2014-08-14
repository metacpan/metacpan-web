#!/usr/bin/env perl

# Fetch the meta.json file from the PerlTV site

use strict;
use warnings;

use FindBin qw ($Bin);
use lib "$Bin/../lib";

use Config::General;
use LWP::Simple;

my $conf   = Config::General->new("$Bin/../metacpan_web.conf");
my %config = $conf->getall;

#use Data::Dumper;
#die Dumper \%config;

my $url = 'http://perltv.org/meta.json';

mirror( $url, $config{perltv_file} );

