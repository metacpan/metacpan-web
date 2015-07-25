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
    mount '/' => Plack::App::Proxy->new(remote => "http://localhost:$port")->to_app;
};
