package MetaCPAN::Web::Test;

# ABSTRACT: Test class for MetaCPAN::Web

use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common;
use HTML::Tree;
use Test::XPath;
use Encode;
use base 'Exporter';
our @EXPORT = qw(
  GET
  test_psgi
  api_response
  app
  tx
);

sub api_response {
    require MetaCPAN::Web::Model::API;

    my $responder = pop;
    my $matches = {@_};

    no warnings 'redefine';
    *MetaCPAN::Web::Model::API::http_request = sub ($$@) {
        my $cb = pop;
        my ($method, $url, %arg) = @_;
        my @res;
        if( ($matches->{if} ? $matches->{if}->(@_) : 1) and @res = $responder->(@_) ) {
            $cb->(@res);
        }
        else {
            @_ = (@_, $cb);
            goto &AnyEvent::HTTP::http_request;
        }
    };
    return;
}

sub app { require 'app.psgi'; }

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

=head2 api_response

Define a sub to intercept api requests and return your own response.

    api_response(sub { return ("body", {"content-type": "text/plain"}) });

Conditionally with another sub:

    api_response(
      if => sub { return $_[1] =~ /foo/ },
      sub { return ("body", {"content-type": "text/plain"}) }
    );

=head2 app

Returns the L<MetaCPAN::Web> psgi app.

=head2 tx($res)

Parses C<< $res->content >> and generates a L<Test::XPath> object.
