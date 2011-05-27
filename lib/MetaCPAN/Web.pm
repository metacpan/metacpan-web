package MetaCPAN::Web;
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/lib";
use Plack::App::URLMap;
use Plack::App::File;
use MetaCPAN::Web::View;
use MetaCPAN::Web::Model;
use Module::Find qw(findallmod);
use Plack::Middleware::Runtime;
use Plack::Middleware::ReverseProxy;

my @controllers = findallmod 'MetaCPAN::Web::Controller';

my $view = MetaCPAN::Web::View->new;
my $model = MetaCPAN::Web::Model->new( url => 'http://' . ($ENV{METACPAN_API} || 'api.beta.metacpan.org') );
my $app = Plack::App::URLMap->new;
$app->map('/static/' => Plack::App::File->new( root => 'static' ));
foreach my $c (@controllers) {
    eval "require $c" || die $@;
    $app->map($c->endpoint => $c->new( view => $view, model => $model ));
}
$app = Plack::Middleware::Runtime->wrap($app);

Plack::Middleware::ReverseProxy->wrap($app);

# ABSTRACT: A Front End for MetaCPAN 
