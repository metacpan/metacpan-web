#!/usr/bin/env plackup -s Twiggy -p 5001
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use Plack::App::URLMap;
use Plack::App::File;
use MetaCPAN::Web::View;
use Module::Find qw(findallmod);
use Plack::Middleware::Runtime;
use Plack::Middleware::ReverseProxy;

my @controllers = findallmod 'MetaCPAN::Web::Controller';

my $view = MetaCPAN::Web::View->new;
my $app = Plack::App::URLMap->new;
$app->map('/static/' => Plack::App::File->new( root => 'static' ));
foreach my $c (@controllers) {
    eval "require $c" || die $@;
    $app->map($c->endpoint => $c->new( view => $view ));
}
$app = Plack::Middleware::Runtime->wrap($app);

Plack::Middleware::ReverseProxy->wrap($app);