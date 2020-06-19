use strict;
use warnings;
use Plack::Builder;
use Plack::App::Proxy;
use File::Basename;
use Config::ZOMG ();

my $root_dir; BEGIN { $root_dir = File::Basename::dirname(__FILE__); }
use lib "$root_dir/lib";

my $port = $ENV{METACPAN_WEB_PORT} || 5001;

my $config = Config::ZOMG->open(
    name => 'MetaCPAN::Web',
    path => $root_dir,
);

builder {
    enable '+MetaCPAN::Middleware::Static' => (
        root => $root_dir,
        config => $config,
        dev_mode => 1,
    );
    enable sub {
        my ($app) = @_;
        sub {
            my ($env) = @_;
            $env->{HTTP_X_FORWARDED_HTTPS} = 'ON'
                if $env->{'psgi.url_scheme'} eq 'https';
            $app->($env);
        };
    };
    mount '/' => Plack::App::Proxy->new(
        remote => "http://localhost:$port",
        preserve_host_header => 1,
        backend => 'LWP',
    )->to_app;
};
