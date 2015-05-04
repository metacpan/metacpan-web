package MetaCPAN::Web::Role::Fastly;

use Moose::Role;
use Net::Fastly;

=head1 NAME

MetaCPAN::Web::Role::Fastly - Methods for fastly intergration

=cut

## Stuff for working with Fastly CDN

has '_surrogate_keys' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        add_surrogate_key   => 'push',
        has_surrogate_keys  => 'count',
        surrogate_keys      => 'elements',
        join_surrogate_keys => 'join',
    },
);

has '_surrogate_keys_to_purge' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
    handles => {
        purge_surrogate_key          => 'push',
        has_surrogate_keys_to_purge  => 'count',
        surrogate_keys_to_purge      => 'elements',
        join_surrogate_keys_to_purge => 'join',
    },
);

sub _net_fastly {
    my $c = shift;

    my $api_key = $c->config->{fastly_api_key};
    my $fsi     = $c->config->{fastly_service_id};

    return unless $api_key && $fsi;

    # We have the credentials, so must be on production
    my $fastly = Net::Fastly->new( api_key => $api_key );
    return $fastly;
}

sub fastly_magic {
    my $c = shift;

    # Surrogate key caching and purging
    if ( $c->has_surrogate_keys ) {

        # See http://www.fastly.com/blog/surrogate-keys-part-1/
        $c->res->header( 'Surrogate-Key' => $c->join_surrogate_keys(' ') );
    }

    if ( $c->has_surrogate_keys_to_purge ) {

        # Something changed, means we need to purge some keys

        my $net_fastly = $c->_net_fastly();
        return unless $net_fastly;

        my $fsi = $c->config->{fastly_service_id};

        foreach my $purge_key ( $c->surrogate_keys_to_purge() ) {
            my $purge_string
                = "https://metacpan.org/${fsi}/purge/${purge_key}";

            $net_fastly->purge($purge_string);
        }
    }

    # Set the caching at CDN, seperate to what the user's browser does
    # https://docs.fastly.com/guides/tutorials/cache-control-tutorial
    if ( $c->cdn_never_cache ) {

        # Make sure fastly doesn't cache this by accident
        $c->res->header( 'Surrogate-Control' => 'no-cache' );

    }
    elsif ( my $ttl = $c->cdn_cache_ttl ) {

        # Use this value
        $c->res->header( 'Surrogate-Control' => 'max_age=' . $ttl );

    }
    elsif ( !$c->res->header('Last-Modified') ) {

        # If Last-Modified, Fastly can use that, otherwise default to no-cache
        $c->res->header( 'Surrogate-Control' => 'no-cache' );

    }
}

# How long should the CDN cache, irrespective of
# other cache headers
has 'cdn_cache_ttl' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub {0},
);

# Make sure the CDN NEVER caches, ignore any other cdn_cache_ttl settings
has 'cdn_never_cache' => (
    is      => 'rw',
    isa     => 'Bool',
    default => sub {0},
);

1;
