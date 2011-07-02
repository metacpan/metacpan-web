#!/usr/bin/env perl

use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use MetaCPAN::Web;

use Plack::Builder;
use Plack::App::File;
use Plack::Middleware::Static;
use Plack::Middleware::Assets;
use Plack::Middleware::Runtime;
use Plack::Middleware::ReverseProxy;
use Plack::Middleware::StackTrace;

MetaCPAN::Web->setup_engine('PSGI');

builder {
    enable 'Runtime';
    enable 'StackTrace';

    enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
        'Plack::Middleware::ReverseProxy';

    # this should be migrated to nginx to lessen load
    enable 'Plack::Middleware::Static',
        path => qr{^/static/}, root => 'root/';

    mount '/favicon.ico' => Plack::App::File->new(file => '/static/icons/favicon.ico');

    mount '/' => sub { MetaCPAN::Web->run(@_) };
};
