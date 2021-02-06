package MetaCPAN::Web::Model::API;

use Moose;
extends 'Catalyst::Model';

use namespace::autoclean;

use Encode ();
use Cpanel::JSON::XS qw( decode_json encode_json );
use IO::Async::Loop;
use IO::Async::SSL;
use IO::Socket::SSL qw( SSL_VERIFY_PEER );
use Net::Async::HTTP;
use URI ();
use URI::QueryParam;
use MetaCPAN::Web::Types qw( Uri );
use Try::Tiny qw( catch try );
use HTTP::Request;
use HTTP::Request::Common ();
use URI::Escape qw( uri_escape );
use Ref::Util qw( is_arrayref );

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

has api => (
    is       => 'ro',
    isa      => Uri,
    coerce   => 1,
    required => 1,
);

has log         => ( is => 'ro' );
has debug       => ( is => 'ro' );
has request_uri => ( is => 'ro' );
has request_id  => ( is => 'ro' );

sub COMPONENT {
    my ( $class, $app, $args ) = @_;

    $args = $class->merge_config_hashes( $class->config, $args );
    $args = $class->merge_config_hashes(
        {
            api   => $app->config->{api},
            log   => $app->log,
            debug => $app->debug,
        },
        $args
    );

    return $class->SUPER::COMPONENT( $app, $args );
}

sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    if ( ref $c and my $r = $c->request ) {
        $self = $self->new(
            %$self,
            request_url => $r->uri,
            (
                $r->env
                ? ( request_id => $r->env->{'MetaCPAN::Web.request_id'}, )
                : ()
            ),
        );
    }
    return $self;
}

sub request {
    my ( $self, $path, $search, $params, $method ) = @_;

    my $url = $self->api->clone;

    $method ||= $search ? 'POST' : 'GET';

    if ( is_arrayref($path) ) {
        $path = join '/', map uri_escape($_), @$path;
    }

    # the order of the following 2 lines matters
    # `path_query` is destructive
    $url->path_query($path);

    my $current_url = $self->request_uri;
    my $request_id  = $self->request_id;
    if ( $method =~ /^(GET|DELETE)$/ || $search ) {
        for my $param ( keys %{ $params || {} } ) {
            $url->query_param( $param => $params->{$param} );
        }
    }

    my $request = HTTP::Request::Common->can($method)->(
        $url,
        (
            $search
            ? (
                'Content-Type' => 'application/json',
                'Content'      => encode_json($search),
                )
            : $method eq 'POST' && $params ? (
                'Content_Type' => 'multipart/form-data',
                'Content'      => $params,
                )
            : ()
        ),
        ( $current_url ? ( 'Referer' => $current_url->as_string )   : () ),
        ( $request_id  ? ( 'X-MetaCPAN-Request-ID' => $request_id ) : () ),
    );

    my $req_p = $self->client->do_request( request => $request );
    $req_p = $req_p->catch( sub {

        # retry once
        $self->client->do_request( request => $request );
    } );
    $req_p->transform(
        done => sub {
            my $response = shift;
            my $logger   = $self->log;
            if ( $self->debug && $logger && $logger->is_debug ) {
                my $content = $request->content;
                if ( length $content > 40 ) {
                    $content = substr( $content, 0, 37 ) . '...';
                }
                $logger->debug(
                    sprintf q[API: "%s %s %s" %s %s%s],
                    $request->method,
                    $url->path_query,
                    $response->protocol // 'TEST',
                    $response->code,
                    length ${ $response->content_ref },
                    ( $content ? " '$content'" : '' )
                );
            }
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
