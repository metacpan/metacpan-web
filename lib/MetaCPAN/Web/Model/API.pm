package MetaCPAN::Web::Model::API;

use Moose;
extends 'Catalyst::Model';

use namespace::autoclean;

use Encode ();
use Cpanel::JSON::XS qw( decode_json encode_json );
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Socket::SSL qw(SSL_VERIFY_PEER);
use Net::Async::HTTP;
use URI;
use URI::QueryParam;
use MetaCPAN::Web::Types qw( Uri );
use Try::Tiny qw( catch try );
use Log::Log4perl;

my $loop;

sub loop {
    $loop ||= IO::Async::Loop->new;
}

my $client;

sub client {
    $client ||= do {
        my $http = Net::Async::HTTP->new(
            user_agent =>
                'MetaCPAN-Web/1.0 (https://github.com/metacpan/metacpan-web)',
            max_connections_per_host => $ENV{NET_ASYNC_HTTP_MAXCONNS} || 5,
            SSL_verify_mode          => SSL_VERIFY_PEER,
            timeout                  => 10,
        );
        $_[0]->loop->add($http);
        $http;
    };
}

has api_secure => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

=head2 COMPONENT

Set C<api_secure> config parameters from the app config object.

=cut

sub COMPONENT {
    my $self = shift;
    my ( $app, $config ) = @_;
    $config->{api_secure} = $app->config->{api_secure};

    return $self->SUPER::COMPONENT( $app, $config );
}

sub model {
    my ( $self, $model ) = @_;
    return MetaCPAN::Web->model('API') unless $model;
    return MetaCPAN::Web->model("API::$model");
}

sub request {
    my ( $self, $path, $search, $params, $method ) = @_;

    my $url = $self->api_secure->clone;

    # the order of the following 2 lines matters
    # `path_query` is destructive
    $url->path_query($path);
    for my $param ( keys %{ $params || {} } ) {
        $url->query_param( $param => $params->{$param} );
    }

    my $current_url = Log::Log4perl::MDC->get('url');

    my $request = HTTP::Request->new(
        (
              $method ? $method
            : $search ? 'POST'
            :           'GET',
        ),
        $url,
        [
            ( $search      ? ( 'Content-Type' => 'application/json' ) : () ),
            ( $current_url ? ( 'Referer'      => $current_url )       : () ),
        ],
    );

    # encode_json returns an octet string
    $request->add_content( encode_json($search) ) if $search;

    $self->client->do_request( request => $request )->transform(
        done => sub {
            my $response = shift;
            my $data = $response->decoded_content( charset => 'none' );
            my $content_type = $response->header('content-type') || '';

            if ( $content_type =~ /^application\/json/ ) {
                my $out;
                eval { $out = decode_json($data); };
                return $out
                    if $out;
            }

            # Response is raw data, e.g. text/plain
            return $self->raw_api_response( $data, $response );
        }
    );
}

# cache these
my $encoding = Encode::find_encoding('utf-8-strict')
    or warn 'UTF-8 Encoding object not found';
my $encode_check = ( Encode::FB_CROAK | Encode::LEAVE_SRC );

# TODO: Check if it's possible for the API to return any other charset.
# Do raw files, git diffs, etc get converted? Any text that goes into ES?

sub raw_api_response {
    my ( $self, $data, $response ) = @_;

    # we have to assume an encoding; doing nothing is like assuming latin1
    # we'll probably have the least number of issues if we assume utf8
    try {
        if ($data) {

         # We could detect a pod =encoding line but any perl code in that file
         # is likely ascii or UTF-8.  We could potentially check for a BOM
         # but those aren't used often and aren't likely to appear here.
         # For now just attempt to decode it as UTF-8 since that's probably
         # what people should be using. (See also #378).
         # decode so the template doesn't double-encode and return mojibake
            $data = $encoding->decode( $data, $encode_check );
        }
    }
    catch {
        warn $_[0];
    };

    return +{ raw => $data, code => $response->code };
}

__PACKAGE__->meta->make_immutable;
1;
