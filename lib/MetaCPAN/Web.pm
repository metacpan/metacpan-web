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
use MetaCPAN::Web::Controller;
use Module::Find qw(findallmod);
use Plack::Middleware::Runtime;
use Plack::Middleware::ReverseProxy;
use Plack::Middleware::StackTrace;

my $api = 'http://' . ( $ENV{METACPAN_API} || 'api.metacpan.org' );
my %models =
  map { eval "require $_" or die $@; $_ => $_->new( url => $api ) }
  'MetaCPAN::Web::Model', findallmod 'MetaCPAN::Web::Model';

my $view = MetaCPAN::Web::View->new;
my $controller =
  MetaCPAN::Web::Controller->new( view => $view, models => \%models );
my $app = Plack::App::URLMap->new;
$app->map( '/static/' => Plack::App::File->new( root => 'static' ) );
$app->map( '/' => $controller->dispatch );
$app = Plack::Middleware::Runtime->wrap($app);
Plack::Middleware::StackTrace->wrap($app);

Plack::Middleware::ReverseProxy->wrap($app);

# ABSTRACT: A Front End for MetaCPAN
