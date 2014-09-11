package MetaCPAN::Web::Model::API;

use Moose;
extends 'Catalyst::Model';

has [qw(api api_secure)] => ( is => 'ro' );

use Encode ();
use JSON::MaybeXS;
use HTTP::Request ();
use AnyEvent::Curl::Multi;
use Try::Tiny 0.09;
use MooseX::ClassAttribute;
use namespace::autoclean;

class_has client => ( is => 'ro', lazy_build => 1 );

sub _build_client {
    return AnyEvent::Curl::Multi->new( max_concurrency => 5 );
}

{
    no warnings 'once';
    $AnyEvent::HTTP::PERSISTENT_TIMEOUT = 0;
    $AnyEvent::HTTP::USERAGENT
        = 'Mozilla/5.0 (compatible; U; MetaCPAN-Web/1.0; '
        . '+https://github.com/CPAN-API/metacpan-web)';
}

sub cv {
    AE::cv;
}

=head2 COMPONENT

Set C<api> and C<api_secure> config parameters from the app config object.

=cut

sub COMPONENT {
    my $self = shift;
    my ( $app, $config ) = @_;
    $config = $self->merge_config_hashes(
        {
            api        => $app->config->{api},
            api_secure => $app->config->{api_secure} || $app->config->{api}
        },
        $config
    );
    return $self->SUPER::COMPONENT( $app, $config );
}

sub model {
    my ( $self, $model ) = @_;
    return MetaCPAN::Web->model('API') unless $model;
    return MetaCPAN::Web->model("API::$model");
}

sub request {
    my ( $self, $path, $search, $params ) = @_;
    my ( $token, $method ) = @$params{qw(token method)};
    $path .= "?access_token=$token" if ($token);
    my $req     = $self->cv;
    my $request = HTTP::Request->new(
        $method ? $method : $search ? 'POST' : 'GET',
        ( $token ? $self->api_secure : $self->api ) . $path,
        [ 'Content-type' => 'application/json' ],
    );

    # encode_json returns an octet string
    $request->add_content( encode_json($search) ) if $search;

    $self->client->request($request)->cv->cb(
        sub {
            my $cv = shift;
            try {
                my ( $response, $stats ) = $cv->recv;
                if ( !$response ) {
                    $req->croak(
                        "bad response when requesting " . $request->uri );
                    return;
                }
                my $content_type = $response->header('content-type') || '';
                my $data = $response->content;

                if ( $content_type =~ /^application\/json/ ) {
                    try {
                        my $json = $self->process_json_response($data);
                        $req->send($json);
                    }
                    catch {
                        $req->send( $self->raw_api_response($data) );
                    };
                }
                else {
                    # Response is raw data, e.g. text/plain
                    $req->send( $self->raw_api_response($data) );
                }
            }
            catch {
                $req->croak($_);
            };
        }
    );
    return $req;
}

sub process_json_response {
    my ( $self, $data ) = @_;

    # Let json error propagate.
    my $json = decode_json($data);

    $self->_strip_source_prefix_from_fields($json);

    return $json;
}

sub _strip_source_prefix_from_fields {
    my ( $self, $json ) = @_;

    # There appears to be a bug in older (than 0.90) ES versions where
    # "A stored boolean field is being returned as a string, not as a boolean"
    # when requested via "fields". To work around this we can specify
    # "_source.blah" in "fields", then we strip the "_source." prefix here.
    # https://github.com/CPAN-API/metacpan-web/issues/881
    # https://github.com/elasticsearch/elasticsearch/issues/2551
    # See .../API/Release.pm for examples of this.

    # Don't autovivify.
    if ( exists( $json->{hits} ) && exists( $json->{hits}->{hits} ) ) {
        foreach my $hit ( @{ $json->{hits}->{hits} } ) {

            next unless exists $hit->{fields};

            my $fields = $hit->{fields};
            foreach my $orig ( keys %$fields ) {
                my $key = $orig;    # copy

                # Strip '_source.' prefix from keys.
                if ( $key =~ s/^_source\.// ) {
                    warn "Field $key overwritten with $orig in ${\ref $self}"
                        if exists $fields->{$key};

                    # Update original reference.
                    $fields->{$key} = delete $fields->{$orig};
                }
            }
        }
    }

    # No return, reference is modified.
}

# cache these
my $encoding = Encode::find_encoding('utf-8-strict')
    or warn 'UTF-8 Encoding object not found';
my $encode_check = ( Encode::FB_CROAK | Encode::LEAVE_SRC );

# TODO: Check if it's possible for the API to return any other charset.
# Do raw files, git diffs, etc get converted? Any text that goes into ES?

sub raw_api_response {
    my ( $self, $data ) = @_;

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

    return +{ raw => $data };
}

1;
