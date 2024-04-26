package MetaCPAN::Web::Model::GitHub;

use Moose;
extends 'Catalyst::Model';

use namespace::autoclean;

use Cpanel::JSON::XS qw( decode_json encode_json );

use IO::Async::Loop       ();
use IO::Async::SSL        ();
use IO::Socket::SSL       qw( SSL_VERIFY_PEER );
use Net::Async::HTTP      ();
use HTTP::Request::Common ();
use MIME::Base64          qw(encode_base64url);
use Crypt::OpenSSL::RSA   ();
use Ref::Util             qw(is_arrayref is_hashref);

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
            max_connections_per_host => $ENV{NET_ASYNC_HTTP_MAXCONNS} || 20,
            SSL_verify_mode          => SSL_VERIFY_PEER,
            timeout                  => 10,
        );
        $_[0]->loop->add($http);
        $http;
    };
}

has app_id          => ( is => 'ro' );
has app_secret_file => ( is => 'ro' );
has app_secret => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        open my $fh, '<', $self->app_secret_file
            or die "can't open " . $self->app_secret_file . "!: $!";
        my $content = do { local $/; <$fh> };
        close $fh;
        return $content;
    },
);
has rsa => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;
        my $rsa  = Crypt::OpenSSL::RSA->new_private_key( $self->app_secret );
        $rsa->use_sha256_hash;
        return $rsa;
    },
);

has _access_token => ( is => 'rw' );

sub jwt {
    my $self = shift;

    my $header = {
        typ => "JWT",
        alg => "RS256",
    };
    my $now     = time;
    my $payload = {
        iat => $now - 60,
        exp => $now + 600,
        iss => 0 + $self->app_id,
    };
    my $jwt_content = join '.', map encode_base64url( encode_json($_) ),
        $header, $payload;

    my $sign = $self->rsa->sign($jwt_content);

    $jwt_content .= '.' . encode_base64url($sign);
    return $jwt_content;
}

sub req {
    my ( $self, $method, $url, $headers, $body ) = @_;

    $url =~ s{^(?:https://api\.github\.com/|/|)}{https://api.github.com/};
    my @headers
        = is_arrayref($headers) ? @$headers
        : is_hashref($headers)  ? %$headers
        :                         die "invalid headers";

    $self->client->do_request(
        method  => $method,
        uri     => $url,
        headers => [
            'Accept'               => 'application/vnd.github+json',
            'X-GitHub-Api-Version' => '2022-11-28',
            @headers,
        ],
        (
            $method eq 'POST'
            ? (
                content      => encode_json( $body || {} ),
                content_type => 'application/json',
                )
            : ()
        ),
    )->then( sub {
        my $response     = shift;
        my $data         = $response->decoded_content( charset => 'none' );
        my $content_type = $response->header('content-type') || q{};

        if ( $content_type =~ /^application\/json/ ) {
            my $out = decode_json($data);
            if ( $response->is_success ) {
                return Future->done($out);
            }
            else {
                return Future->fail($out);
            }
        }
        else {
            return Future->fail($data);
        }
    } );
}

sub access_token {
    my $self          = shift;
    my $current_token = $self->_access_token;
    if ( $current_token && $current_token->{expires_at} > time ) {
        return Future->done( $current_token->{token} );
    }
    my $jwt = $self->jwt;
    $self->req( 'GET', 'integration/installations',
        [ 'Authorization' => 'Bearer ' . $jwt ],
    )->then( sub {
        my $res = shift;
        my ($installation) = @$res;
        $self->req(
            'POST',
            $installation->{access_tokens_url},
            [ 'Authorization' => 'Bearer ' . $jwt ],
        );
    } )->then( sub {
        my $token      = shift;
        my $expires_at = DateTime::Format::ISO8601->parse_datetime(
            $token->{expires_at} );
        $token->{expires_at} = $expires_at->epoch;
        $self->_access_token($token);
        return Future->done( $token->{token} );
    } );
}

sub maybe_auth {
    my $self = shift;
    return Future->done( [] )
        if !$self->app_id;
    $self->access_token->then( sub {
        Future->done( [ 'Authorization' => "token " . shift ] );
    } );
}

sub contributors {
    my $self = shift;
    $self->maybe_auth->then( sub {
        my $auth = shift;
        $self->req( 'GET', 'orgs/metacpan/repos?type=public&per_page=100',
            [@$auth], )->then( sub {
            my $repos = shift;
            warn "found " . scalar(@$repos) . ' repositories';
            Future->wait_all(
                map $self->req(
                    'GET', "repos/$_->{full_name}/contributors", [@$auth],
                ),
                @$repos
            );
            } );
    } )->then( sub {
        my (@results) = @_;
        my %users;
        for my $result ( map @{ $_->get }, @results ) {
            my $user = $users{ $result->{login} }
                ||= { %$result, contributions => 0 };
            $user->{contributions} += $result->{contributions};
        }
        return [
            sort {
                $b->{contributions} <=> $a->{contributions}
                    || lc $a->{login} cmp lc $b->{login}
            }
            grep {
                       $_->{type} ne 'Bot'
                    && $_->{id} != 87378114    # metacpan-bot
            } values %users
        ];
    } );
}

__PACKAGE__->meta->make_immutable;
1;
