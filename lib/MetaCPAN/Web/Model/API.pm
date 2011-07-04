package MetaCPAN::Web::Model::API;

use Moose;
extends 'Catalyst::Model';

has api => ( is => 'ro' );

use MetaCPAN::Web::MyCondVar;
use Test::More;
use JSON;
use AnyEvent::HTTP qw(http_request);

sub cv {
    MetaCPAN::Web::MyCondVar->new;
}

=head2 COMPONENT

Merge config of this model with the config of Model::API.

=cut

sub COMPONENT {
    my $self = shift;
    my ( $app, $config ) = @_;
    $config = $self->merge_config_hashes( { api => $app->config->{api} },
        $config );
    return $self->SUPER::COMPONENT( $app, $config );
}

sub model {
    my ( $self, $model ) = @_;
    return MetaCPAN::Web->model('API') unless $model;
    return MetaCPAN::Web->model("API::$model");
}

sub request {
    my ( $self, $path, $search, $params ) = @_;
    my $req = $self->cv;
    http_request $search ? 'post' : 'get' => 'http://' . $self->api . $path,
        body => $search ? encode_json($search) : '',
        persistent => 1,
        $params->{msid}
        ? (
        cookie_jar => $self->_build_cookie( $self->api, $params->{msid} ) )
        : (), sub {
        my ( $data, $headers ) = @_;
        my $content_type = $headers->{'content-type'} || '';

        if ( $content_type =~ /^application\/json/ ) {
            my $json = eval { decode_json($data) };
            $req->send( $@ ? { raw => $data } : $json );
        }
        else {

            # Response is raw data, e.g. text/plain
            $req->send( { raw => $data } );
        }
        };
    return $req;
}

sub _build_cookie {
    my ( $self, $api, $value ) = @_;
    $api =~ s/:\d+$//;
    return {
        version => 1,
        $api    => {
            '/' => {
                metacpan_api => { _expires => 2383111257, value => $value }
            }
        }
    };
}

1;
