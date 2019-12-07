package MetaCPAN::Web::App;    ## no critic (RequireFilenameMatchesPackage)

# ABSTRACT: Modern front-end for MetaCPAN

use strict;
use warnings;

# TODO: When we know everything will work reliably: $ENV{PLACK_ENV} ||= 'development';
#
use File::Basename;
use Config::ZOMG ();
use Log::Log4perl;
use File::Spec;
use File::Path ();
use File::Find ();
use Plack::Builder;
use Digest::SHA;

my $root_dir;
my $dev_mode;
my $config;

BEGIN {
    $root_dir = File::Basename::dirname(__FILE__);
    $dev_mode = $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development';
    $config   = Config::ZOMG->open(
        name => 'MetaCPAN::Web',
        path => $root_dir,
    );

    if ($dev_mode) {
        $ENV{PLACK_SERVER}       = 'Standalone';
        $ENV{METACPAN_WEB_DEBUG} = 1;
    }

    my $log4perl_config
        = File::Spec->rel2abs( $config->{log4perl_file} || 'log4perl.conf',
        $root_dir );
    Log::Log4perl::init($log4perl_config);

# use a unique package and tell l4p to ignore it when finding the warning location.
    package MetaCPAN::Web::WarnHandler;
    Log::Log4perl->wrapper_register(__PACKAGE__);
    my $logger = Log::Log4perl->get_logger;
    $SIG{__WARN__} = sub { $logger->warn(@_) };

    $dev_mode and require Devel::Confess and Devel::Confess->import;
}

use lib "$root_dir/lib";
use MetaCPAN::Web;

# do not use the read only mount point when running from a docker container
my $tempdir = is_linux_container() ? "/var/tmp" : "$root_dir/var/tmp";

STDERR->autoflush;

# rmtree causes warnings when tests are running
if ( !$dev_mode && !$ENV{HARNESS_ACTIVE} ) {
    my $view = MetaCPAN::Web->view('HTML');

    if ( my $tmpl_cache = $view->config->{COMPILE_DIR} ) {
        File::Path::rmtree( [ glob "$tmpl_cache/*" ] );
    }

    my @tmpl_dir = @{ $view->include_path };
    my $alloy    = Template::Alloy->new( $view->config );

    s{/\z}{} for @tmpl_dir;

    my @templates;
    for my $tmpl_dir (@tmpl_dir) {
        File::Find::find(
            {
                no_chdir => 1,
                wanted   => sub {
                    if ( $_ eq $tmpl_dir . '/static' ) {
                        $File::Find::prune = 1;
                        return;
                    }

                    return
                        if -d;

                    push @templates, File::Spec->abs2rel( $_, $tmpl_dir );
                },
            },
            $tmpl_dir,
        );
    }

    for my $template (@templates) {

        # might fail if we try to load something that isn't actually a
        # template, and it can't be parsed.  Although that shouldn't happen
        # because we are skipping static files.
        eval { $alloy->load_template($template) };
    }
}

# explicitly call ->to_app on every Plack::App::* for performance
builder {

    enable sub {
        my $app = shift;
        sub {
            my ($env) = @_;
            if ( $env->{HTTP_FASTLY_SSL} ) {
                $env->{HTTPS}             = 'ON';
                $env->{'psgi.url_scheme'} = 'https';
            }
            if ( my $host = $env->{HTTP_X_FORWARDED_HOST} ) {
                $env->{HTTP_HOST} = $host;
            }
            if ( my $port = $env->{HTTP_X_FORWARDED_PORT} ) {
                $env->{SERVER_PORT} = $port;
            }
            if ( my $addrs = $env->{HTTP_X_FORWARDED_FOR} ) {
                my @addrs = map s/^\s+//r =~ s/\s+$//r, split /,/, $addrs;
                $env->{REMOTE_ADDR} = $addrs[0];
            }
            $app->($env);
        };
    };
    enable sub {
        my $app = shift;
        sub {
            my ($env) = @_;
            my $request_id = Digest::SHA::sha1_hex( join( "\0",
                $env->{REMOTE_ADDR}, $env->{REQUEST_URI}, time, $$, rand, ) );
            $env->{'MetaCPAN::Web.request_id'} = $request_id;

            Log::Log4perl::MDC->remove;
            Log::Log4perl::MDC->put( "request_id", $request_id );
            Log::Log4perl::MDC->put( "ip",         $env->{REMOTE_ADDR} );
            Log::Log4perl::MDC->put( "method",     $env->{REMOTE_METHOD} );
            Log::Log4perl::MDC->put( "url",        $env->{REQUEST_URI} );
            Log::Log4perl::MDC->put( "referer",    $env->{HTTP_REFERER} );
            $app->($env);
        };
    };
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
        die 'cookie_secret not configured'
            unless $config->{cookie_secret};

        # Add session cookie here only
        enable 'Session::Cookie::MetaCPAN' => (
            session_key => 'metacpan_secure',
            expires     => 2**30,
            secure      => ( !$dev_mode ),
            httponly    => 1,
            secret      => $config->{cookie_secret},
        );

        MetaCPAN::Web->psgi_app;
    };
};

sub is_linux_container {
    return -e '/proc/1/cgroup';
}

