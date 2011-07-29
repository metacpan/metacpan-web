package MetaCPAN::Web::API::Request;

use Moose::Role;
use namespace::autoclean;

use AnyEvent::HTTP qw(http_request);
use JSON;
use MetaCPAN::Web::MyCondVar;

sub cv {
    MetaCPAN::Web::MyCondVar->new;
}

has api => (
    default => 'http://api.metacpan.org',
    is      => 'ro',
    isa     => 'Str',
);

has api_secure => (
    default => 'https://api.metacpan.org',
    is      => 'ro',
    isa     => 'Str',
);

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
