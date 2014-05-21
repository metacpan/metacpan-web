#!/usr/local/perlbrew/perls/perl-5.16.2/bin/perl

# usage: perl bin/daemon_control.pl get_init_file > /path/to/init/script

use strict;
use warnings;

use Daemon::Control;
use Sys::Hostname qw( hostname );

my $name    = 'metacpan-www';
my $user    = 'metacpan';
my $home    = '/home/metacpan/metacpan.org';
my $carton  = '/usr/local/perlbrew/perls/perl-5.16.2/bin/carton';
my $workers = 7;

if ( hostname() eq 'debian' ) {
    $user    = 'vagrant';
    $workers = 3;
}

my @program_args = (
    'exec', '/usr/local/perlbrew/perls/perl-5.16.2/bin/plackup',
    '--port'    => 5001,
    '--workers' => $workers,
    '-E'        => 'production',
    '-Ilib',
    '-a'  => 'app.psgi',
    '-s', => 'Starman',
);

# Notes on unused args
# scan_name: seems to be just 'starman master' (not useful)
# stdout_file: always seems to be just empty

my $args = {
    directory    => $home,
    fork         => 2,
    group        => $user,
    init_config  => "$home/.metacpanrc",
    lsb_desc     => "Starts $name",
    lsb_sdesc    => "Starts $name",
    name         => $name,
    path         => "$home/bin/daemon-control.pl",
    pid_file     => "$home/var/run/$name.pid",
    program      => $carton,
    program_args => \@program_args,
    stderr_file  => "$home/var/logs/starman_error.log",
    user         => $user,
};

Daemon::Control->new($args)->run;
