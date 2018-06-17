use strict;
use warnings;
use Plack::Builder;
use Plack::App::Proxy;
use File::Basename;
my $root_dir; BEGIN { $root_dir = File::Basename::dirname(__FILE__); }
use lib "$root_dir/lib";

my $port = $ENV{METACPAN_WEB_PORT} || 5001;

builder {
    enable '+MetaCPAN::Middleware::Static' => root => $root_dir;
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
    )->to_app;
};
