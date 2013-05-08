package MetaCPAN::Web::Test;

# ABSTRACT: Test class for MetaCPAN::Web

use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common;
use HTTP::Message::PSGI;
use HTML::Tree;
use Test::XPath;
use Encode;
use base 'Exporter';
our @EXPORT = qw(
  GET
  test_psgi
  override_api_response
  app
  tx
);

# TODO: use Sub:Override?
# save a copy in case we override
my $orig_request = \&AnyEvent::Curl::Multi::request;

sub override_api_response {
    require MetaCPAN::Web::Model::API;

    my $responder = pop;
    my $matches = {@_};

    no warnings 'redefine';
    *AnyEvent::Curl::Multi::request = sub {
        if( ($matches->{if} ? $matches->{if}->(@_) : 1) and my $res = $responder->(@_) ) {
            $res = HTTP::Response->from_psgi($res) if ref $res eq 'ARRAY';
            # return an object with a ->cv that's ready so that the cb will fire
            my $ret = bless { cv => AE::cv() }, 'AnyEvent::Curl::Multi::Handle';
            $ret->cv->send($res, {});
            return $ret;
        }
        else {
            goto &$orig_request;
        }
    };
    return;
}

sub app { require 'app.psgi'; }

sub tx {
    my $tree = HTML::TreeBuilder->new_from_content( shift->content );
    my $xml  = $tree->as_XML;
    $xml = decode_utf8($xml);
    my $tx = Test::XPath->new( xml => $xml );
    # https://metacpan.org/module/DWHEELER/Test-XPath-0.16/lib/Test/XPath.pm#xpc
    $tx->xpc->registerFunction( grep => sub {
        my ($nodelist, $regex) =  @_;
        my $result = XML::LibXML::NodeList->new;
        for my $node ($nodelist->get_nodelist) {
            $result->push($node) if $node->textContent =~ $regex;
        }
        return $result;
    } );
    return $tx;
}

1;

=head1 ENVIRONMENTAL VARIABLES

Sets C<PLACK_TEST_IMPL> to C<Server> and C<PLACK_SERVER> to C<Twiggy>.

=head1 EXPORTS

=head2 GET

L<HTTP::Request::Common/GET>

=head2 test_psgi

L<Plack::Test/test_psgi>

=head2 override_api_response

Define a sub to intercept api requests and return your own response.
Response can be L<HTTP::Response> or a PSGI array ref.

    override_api_response(sub { return [ 200, ["Content-Type" => "text/plain"], ["body"] ]; });

Conditionally with another sub:

    override_api_response(
      if => sub { return $_[1] =~ /foo/ },
      sub { return HTTP::Response->new(200, "OK", ["Content-type" => "text/plain"], "body"); }
    );

=head2 app

Returns the L<MetaCPAN::Web> psgi app.

=head2 tx($res)

Parses C<< $res->content >> and generates a L<Test::XPath> object.
