package MetaCPAN::Web;

# ABSTRACT: Modern front-end for MetaCPAN

use strict;
use warnings;

BEGIN {
    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {
        $ENV{PLACK_SERVER}       = 'Standalone';
        $ENV{METACPAN_WEB_DEBUG} = 1;
    }
}

use FindBin;
use lib "$FindBin::RealBin/lib";
use File::Path ();
use MetaCPAN::Web;
use Plack::App::File;
use Plack::App::URLMap;
use Plack::Middleware::Assets;
use Plack::Middleware::Runtime;
use Plack::Middleware::ReverseProxy;
use Plack::Middleware::Session::Cookie;
use Plack::Middleware::ServerStatus::Lite;

my $app = Plack::App::URLMap->new;
$app->map( '/static/' => Plack::App::File->new( root => 'root/static' ) );
$app->map( '/favicon.ico' =>
        Plack::App::File->new( file => 'root/static/icons/favicon.ico' ) );
$app->map( '/' => MetaCPAN::Web->psgi_app );
my $scoreboard = "$FindBin::RealBin/var/tmp/scoreboard";
unless (-d $scoreboard) {
    File::Path::make_path($scoreboard) or die "Can't make_path $scoreboard: $!";
}
$app = Plack::Middleware::ServerStatus::Lite->wrap(
   $app,
   path       => '/server-status',
   allow      => ['127.0.0.1'],
   scoreboard => $scoreboard,
) unless $0 =~ /\.t$/;
$app = Plack::Middleware::Runtime->wrap($app);
$app = Plack::Middleware::Assets->wrap( $app,
    files => [<root/static/css/*.css>] );
$app = Plack::Middleware::Assets->wrap(
    $app,

# should we autoload the syntax brushes or otherwise specify which ones are needed (instead of "all")?
    files => [
        map {"root/static/js/$_.js"}
            qw(
            jquery.min
            jquery.tablesorter
            jquery.cookie
            jquery.relatize_date
            jquery.ajaxQueue
            jquery.qtip.pack
            jquery.autocomplete.pack
            shCore
            shBrushPerl
            shBrushPlain
            shBrushYaml
            shBrushJScript
            shBrushDiff
            shBrushCpp
            shBrushCPANChanges
            cpan
            toolbar
            github
            contributors
            bootstrap/bootstrap-dropdown
            bootstrap/bootstrap-collapse
            less.min
            )
    ],
);

Plack::Middleware::ReverseProxy->wrap(
    sub {
        my $env    = shift;
        my $secure = $env->{'HTTP_X_FORWARDED_PORT'}
            && $env->{'HTTP_X_FORWARDED_PORT'} eq '443';
        Plack::Middleware::Session::Cookie->wrap(
            $app,
            session_key => $secure
            ? 'metacpan_secure'
            : 'metacpan',
            expires => 2**30,
            $secure ? ( secure => 1 ) : (),
            httponly => 1,
        )->($env);
    }
);
