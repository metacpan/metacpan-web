use strict;

use Plack::App::File;

use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Path::Class;
use Plack::Middleware::MCLess;

use CHI;

use File::Temp qw/ tempdir /;

my $cache_dir = tempdir( CLEANUP => 1 );

my $cache = CHI->new(
    driver   => 'File',
    root_dir => $cache_dir,
);

my $app = builder {

    enable 'Plack::Middleware::MCLess',
        cache => $cache,
        root  => 't/plack/css',
        files => ['t/plack/css/style.less'];

    return sub {
        my $env = shift;
        [
            200,
            [ 'Content-type', 'text/plain' ],
            [ map { $_ . $/ } @{ $env->{'psgix.assets_less'} } ]
        ];
        }
};

my $assets;
my $total = 1;

test_psgi $app, sub {
    my $cb = shift;

    {
        my $res = $cb->( GET 'http://localhost/' );
        is( $res->code, 200 );
        $assets = [ split( $/, $res->content ) ];
        is @$assets, $total, 'Number of assets matches';
    }

    {
        like( $assets->[0], qr/\.css$/, '.css file extension' );
        my $res = $cb->( GET 'http://localhost' . $assets->[0] );
        is $res->code,         200;
        is $res->content_type, 'text/css';
        is $res->content,      '#header{color:#4d926f}h2{color:#4d926f}',
            'Content matches';
    }

};

eval {
    builder {

        enable 'Plack::Middleware::MCLess',
            root  => 't/plack/css',
            files => ['t/plack/css/broken.less'];

    };
};
my $error = $@;
like $error, qr/(Syntax|Parse)Error/, 'Error ok';

done_testing;
