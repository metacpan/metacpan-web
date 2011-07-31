package MetaCPAN::Web::API::Request;

use Moose::Role;
use namespace::autoclean;

use AnyEvent::HTTP qw(http_request);
use JSON;
use MetaCPAN::Web::MyCondVar;
use MetaCPAN::Web::API::Result;

sub cv {
    MetaCPAN::Web::MyCondVar->new;
}

has url => (
    default => 'http://api.metacpan.org',
    is      => 'ro',
    isa     => 'Str',
);

has url_secure => (
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
        : 'get' => ( $token ? $self->url_secure : $self->url ) . $path,
        body => $search ? encode_json($search) : undef,
        headers    => { 'Content-type' => 'application/json' },
        persistent => 1,
        sub {
        my ( $data, $headers ) = @_;
        my $content_type = $headers->{'content-type'} || '';

        if ( $content_type =~ /^application\/json/ ) {
            my $json = eval { decode_json($data) };
            my $result = $@ ? { raw => $data } : $json;
            $req->send( bless $result, 'MetaCPAN::Web::API::Result' );
        }
        else {

            # Response is raw data, e.g. text/plain
            $req->send( { raw => $data } );
        }
        };
    return $req;
}

1;
