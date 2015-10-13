package MetaCPAN::Web;    ## no critic (RequireFilenameMatchesPackage)

# ABSTRACT: Modern front-end for MetaCPAN

use strict;
use warnings;

# TODO: When we know everything will work reliably: $ENV{PLACK_ENV} ||= 'development';
#
use File::Basename;
my $root_dir;
my $dev_mode;

BEGIN {
    $root_dir = File::Basename::dirname(__FILE__);
    $dev_mode = $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
}

BEGIN {
    if ($dev_mode) {
        $ENV{PLACK_SERVER}       = 'Standalone';
        $ENV{METACPAN_WEB_DEBUG} = 1;
    }
}

use lib "$root_dir/lib";
use Config::JFDI;
use File::Path ();
use MetaCPAN::Web;
use Plack::Builder;

my $tempdir = "$root_dir/var/tmp";

# explicitly call ->to_app on every Plack::App::* for performance
builder {

    enable 'ReverseProxy';
    enable 'Runtime';

    unless ( $ENV{HARNESS_ACTIVE} or $0 =~ /\.t$/ ) {
        my $scoreboard = "$tempdir/scoreboard";
        File::Path::make_path($scoreboard);

        enable 'ServerStatus::Lite' => (
            path       => '/server-status',
            allow      => ['127.0.0.1'],
            scoreboard => $scoreboard,
        );
    }

    enable '+MetaCPAN::Middleware::Static' => (
        root     => $root_dir,
        dev_mode => $dev_mode,
        temp_dir => $tempdir,
    );

    builder {
        my $config = Config::JFDI->new(
            name => 'MetaCPAN::Web',
            path => $root_dir,
        );

        die 'cookie_secret not configured'
            unless $config->get->{cookie_secret};

        # Add session cookie here only
        enable 'Session::Cookie::MetaCPAN' => (
            session_key => 'metacpan_secure',
            expires     => 2**30,
            secure      => ( !$dev_mode ),
            httponly    => 1,
            secret      => $config->get->{cookie_secret},
        );

        MetaCPAN::Web->psgi_app;
    };
};
