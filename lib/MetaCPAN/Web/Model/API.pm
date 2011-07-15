package MetaCPAN::Web::Model::API;

use Moose;
extends 'Catalyst::Model';

has [qw(api api_secure)] => ( is => 'ro' );

use MetaCPAN::Web::MyCondVar;
use Test::More;
use JSON;
use AnyEvent::HTTP qw(http_request);

sub cv {
    MetaCPAN::Web::MyCondVar->new;
}

=head2 COMPONENT

Set C<api> and C<api_secure> config parameters from the app config object.

=cut

sub COMPONENT {
    my $self = shift;
    my ( $app, $config ) = @_;
    $config = $self->merge_config_hashes(
        {   api        => $app->config->{api},
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
    my $req = $self->cv;
    http_request $method ? $method
        : $search        ? 'post'
        : 'get' => ( $token ? $self->api_secure : $self->api ) . $path,
        body => $search ? encode_json($search) : undef,
        headers    => { 'Content-type' => 'application/json' },
        persistent => 1,
        sub {
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

1;
