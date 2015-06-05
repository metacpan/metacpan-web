package MetaCPAN::Web::Role::Fastly;

use Moose::Role;
use Net::Fastly;

use MetaCPAN::Web::Types qw( ArrayRef Str );

=head1 NAME

MetaCPAN::Web::Role::Fastly - Methods for fastly intergration

=head1 METHODS

The following:

=head2 $c->add_surrogate_key('foo');

=head2 $c->purge_surrogate_key('bar');

=head2 $c->cdn_cache_ttl(3600);

Are applied when:

=head2 $c->fastly_magic()

   is run in the L<end>, however if

=head2 $c->cdn_never_cache(1)

Is set fastly is forced to NOT cache, no matter
what other options have been set

=cut

## Stuff for working with Fastly CDN

has '_surrogate_keys' => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => ArrayRef [Str],
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
    isa     => ArrayRef [Str],
    default => sub { [] },
    handles => {
        purge_surrogate_key          => 'push',
        has_surrogate_keys_to_purge  => 'count',
        surrogate_keys_to_purge      => 'elements',
        join_surrogate_keys_to_purge => 'join',
    },
);

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

    # Some action must have triffered a purge
    if ( $c->has_surrogate_keys_to_purge ) {

        # Something changed, means we need to purge some keys
        my @tags = $c->surrogate_keys_to_purge();

        $c->cdn_purge_now(
            {
                tags => \@tags,
            }
        );
    }

    # Surrogate key caching and purging
    if ( $c->has_surrogate_keys ) {

        # See http://www.fastly.com/blog/surrogate-keys-part-1/
        $c->res->header( 'Surrogate-Key' => $c->join_surrogate_keys(' ') );
    }

    # Set the caching at CDN, seperate to what the user's browser does
    # https://docs.fastly.com/guides/tutorials/cache-control-tutorial
    if ( $c->cdn_never_cache ) {

        # Make sure fastly doesn't cache this by accident
        $c->res->header( 'Surrogate-Control' => 'no-cache' );

    }
    elsif ( my $ttl = $c->cdn_cache_ttl ) {

        # TODO: https://www.fastly.com/blog/stale-while-revalidate/
        # Use this value
        $c->res->header( 'Surrogate-Control' => 'max-age=' . $ttl );

    }
    elsif ( !$c->res->header('Last-Modified') ) {

        # If Last-Modified, Fastly can use that, otherwise default to no-cache
        $c->res->header( 'Surrogate-Control' => 'no-cache' );

    }
}

=head2 cdn_purge_now

  $c->cdn_purge_now({
    tags => [ 'foo', 'bar' ]
    urls => [ 'this', 'and/that' ],
  });

=cut

sub cdn_purge_now {
    my ( $c, $args ) = @_;

    my $net_fastly = $c->_net_fastly();
    return unless $net_fastly;

    my $fsi = $c->config->{fastly_service_id};

    foreach my $tag ( @{ $args->{tags} || [] } ) {
        my $purge_string = "https://metacpan.org/${fsi}/purge/${tag}";
        $net_fastly->purge($purge_string);
    }

    foreach my $url ( @{ $args->{urls} || [] } ) {
        my $purge_string = "https://metacpan.org/${url}";
        $net_fastly->purge($purge_string);
    }
}

=head2 cdn_purge_all

  $c->cdn_purge_all()

=cut

sub cdn_purge_all {
    my $c          = shift;
    my $net_fastly = $c->_net_fastly();

    die "No access" unless $net_fastly;

    my $fsi = $c->config->{fastly_service_id};

    my $purge_string = "/service/${fsi}/purge_all";

    $net_fastly->purge($purge_string);
}

1;
