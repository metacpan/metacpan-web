package MetaCPAN::Web::Test;

# ABSTRACT: Test class for MetaCPAN::Web

BEGIN {
    $ENV{PLACK_TEST_IMPL} = "Server";
    $ENV{PLACK_SERVER} = "Twiggy";
}

use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common;
use HTML::Tree;
use Test::XPath;
use Encode;
use base 'Exporter';
our @EXPORT = qw(GET test_psgi app tx);

sub app { require MetaCPAN::Web; }

sub tx {
    my $tree = HTML::TreeBuilder->new_from_content( shift->content );
    my $xml  = $tree->as_XML;
    $xml = decode_utf8($xml);
    return Test::XPath->new( xml => $xml );
}

1;

=head1 ENVIRONMENTAL VARIABLES

Sets C<PLACK_TEST_IMPL> to C<Server> and C<PLACK_SERVER> to C<Twiggy>.

=head1 EXPORTS

=head2 GET

L<HTTP::Request::Common/GET>

=head2 test_psgi

L<Plack::Test/test_psgi>

=head2 app

Returns the L<MetaCPAN::Web> psgi app.

=head2 tx($res)

Parses C<< $res->content >> and generates a L<Test::XPath> object.