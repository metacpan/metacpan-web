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
use Plack::Builder;
use Plack::App::File;
use Plack::App::URLMap;
use Plack::Middleware::Assets;
use Plack::Middleware::Headers;
use Plack::Middleware::Runtime;
use Plack::Middleware::MCLess;
use Plack::Middleware::ReverseProxy;
use Plack::Middleware::Session::Cookie;
use Plack::Middleware::ServerStatus::Lite;

# explicitly call ->to_app on every Plack::App::* for performance
my $app = Plack::App::URLMap->new;

# Static content
{
    my $static_app = Plack::App::File->new( root => 'root/static' )->to_app;
    $app->map( '/static/' => $static_app );
}

# favicon
{
    my $fav_app
        = Plack::App::File->new( file => 'root/static/icons/favicon.ico' )
        ->to_app;
    $app->map( '/favicon.ico' => $fav_app );
}

# Main catalyst app
{
    my $core_app = MetaCPAN::Web->psgi_app;

    # Add session cookie here only
    $core_app = Plack::Middleware::Session::Cookie->wrap(
        $core_app,
        session_key => 'metacpan_secure',
        expires     => 2**30,
        secure      => ($ENV{PLACK_ENV} ne 'development'),
        httponly    => 1,
    );

    $app->map( '/' => $core_app );
}

$app = $app->to_app;

unless ( $ENV{HARNESS_ACTIVE} ) {
    my $scoreboard = "$FindBin::RealBin/var/tmp/scoreboard";
    unless ( -d $scoreboard ) {
        File::Path::make_path($scoreboard)
            or die "Can't make_path $scoreboard: $!";
    }
    $app = Plack::Middleware::ServerStatus::Lite->wrap(
        $app,
        path       => '/server-status',
        allow      => ['127.0.0.1'],
        scoreboard => $scoreboard,
    ) unless $0 =~ /\.t$/;
}

$app = Plack::Middleware::Runtime->wrap($app);
$app = Plack::Middleware::Assets->wrap( $app,
    files => [<root/static/css/*.css>] );
$app = Plack::Middleware::Assets->wrap(
    $app,
    files => [
        map {"root/static/js/$_.js"}
            qw(
            jquery.min
            jquery.tablesorter
            jquery.cookie
            jquery.relatize_date
            jquery.ajaxQueue
            jquery.qtip.pack
            jquery.autocomplete.min
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
            dropdown
            bootstrap/bootstrap-dropdown
            bootstrap/bootstrap-collapse
            bootstrap/bootstrap-modal
            bootstrap/bootstrap-tooltip
            bootstrap-slidepanel
            )
    ],
);

use CHI;

if ( !$ENV{PLACK_ENV} || $ENV{PLACK_ENV} ne 'development' ) {

    # Only need for live
    my $cache = CHI->new(
        driver   => 'File',
        root_dir => '/tmp/less.cache'
    );

    # Wrap up to serve lessc parsed files
    $app = Plack::Middleware::MCLess->wrap(
        $app,
        cache     => $cache,
        cache_ttl => "60 minutes",
        root      => "root/static",
        files     => [
            map {"root/static/less/$_.less"}
                qw(
                style
                )
        ],
    );

}

# Handle surrogate (fastly caching)
{
    my $hour_ttl = 60 * 60;
    my $day_ttl  = $hour_ttl * 24;

    $app = builder {

        # Tell fastly to cache _asset and _asset_less for a day
        enable_if { $_[0]->{PATH_INFO} =~ m{^/_asset} } 'Headers',
            set => [ 'Surrogate-Control' => "max-age=${day_ttl}" ];

        # Tell fastly to cache /static/ for an hour
        enable_if { $_[0]->{PATH_INFO} =~ m{^/static} } 'Headers',
            set => [ 'Surrogate-Control' => "max-age=${hour_ttl}" ];

        $app;
    };
}

$app = Plack::Middleware::ReverseProxy->wrap($app);

return $app;
