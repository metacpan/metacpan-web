use strict;
use Plack::App::File;
use Plack::Middleware::MCLess;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Data::Dumper;

my $app = Plack::App::File->new(root => "t/plack/css");
$app = Plack::Middleware::MCLess->wrap($app, root => "t/plack/css");

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/foo.less");
    is $res->code, 200;
    is $res->content_type, 'text/css';
    like $res->content, qr/color: #4D926F;/i, "Content match for foo.less";

    # Something that uses includes
    $res = $cb->(GET "/style.less");
    is $res->code, 200;
    is $res->content_type, 'text/css';
    like $res->content, qr/\scolor: #4D926F;/i;

    $res = $cb->(GET "/missing.less");
    is $res->code, 404, '404 for a missing less file';

    $res = $cb->(GET "/broken.less");
    is $res->code, 500, '500 for a broken less file';

};

done_testing;