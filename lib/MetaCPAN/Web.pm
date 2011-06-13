package MetaCPAN::Web;

# ABSTRACT: Modern front-end for MetaCPAN
use strict;
use warnings;
use FindBin;
use lib "$FindBin::RealBin/../";
use Plack::App::URLMap;
use Plack::App::File;
use MetaCPAN::Web::View;
use MetaCPAN::Web::Model;
use Module::Find qw(findallmod);
use Plack::Middleware::Runtime;
use Plack::Middleware::ReverseProxy;
use Plack::Middleware::StackTrace;

my @controllers = findallmod 'MetaCPAN::Web::Controller';

my $api = 'http://' . ( $ENV{METACPAN_API} || 'api.metacpan.org' );

my $view = MetaCPAN::Web::View->new;
my $model = MetaCPAN::Web::Model->new( url => $api );
my $app  = Plack::App::URLMap->new;
$app->map( '/static/' => Plack::App::File->new( root => 'static' ) );
foreach my $c (@controllers) {
    eval "require $c" || die $@;
    $app->map( $c->endpoint => $c->new( view => $view, model => $model ) );
}
$app = Plack::Middleware::Runtime->wrap($app);
Plack::Middleware::StackTrace->wrap($app);

Plack::Middleware::ReverseProxy->wrap($app);

# ABSTRACT: A Front End for MetaCPAN
