package MetaCPAN::Web::Role::Fastly;

use Moose::Role;
use Net::Fastly;

use MetaCPAN::Web::Types qw(:all);

=head1 NAME

MetaCPAN::Web::Role::Fastly - Methods for fastly intergration

=head1 METHODS

The following:

=head2 $c->add_surrogate_key('FOO');

=head2 $c->purge_surrogate_key('BAR');

=head2 $c->cdn_cache_ttl( $c->cdn_times->{one_day} );

Are applied when:

=head2 $c->fastly_magic()

   is run in the L<end>, however if

=head2 $c->cdn_never_cache(1)

Is set fastly is forced to NOT cache, no matter
what other options have been set

=head2 $c->browser_max_age( $c->cdn_times->{'one_day'});

=head2 $c->cdn_times;

Returns a hashref of 'one_hour', 'one_day', 'one_week'
and 'one_year' so we don't have numbers all over the place

=cut

## Stuff for working with Fastly CDN

has _surrogate_keys => (
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

has _surrogate_keys_to_purge => (
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
has cdn_cache_ttl => (
    is      => 'rw',
    isa     => Int,
    default => sub {0},
);

# Make sure the CDN NEVER caches, ignore any other cdn_cache_ttl settings
has cdn_never_cache => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has browser_max_age => (
    is      => 'rw',
    isa     => Maybe[Int],
    default => sub {undef},
);

has cdn_times => (
    is         => 'ro',
    isa        => 'HashRef',
    lazy_build => 1,
);

sub datacenters {
    my ($c) = @_;
    my $net_fastly = $c->_net_fastly();
    return unless $net_fastly;

    # Uses the private interface as fastly client doesn't
    # have this end point yet
    my $datacenters = $net_fastly->client->_get('/datacenters');
    return $datacenters;
}

sub _build_cdn_times {
    return {
        one_min     => 60,
        ten_mins    => 600,
        thirty_mins => 1800,
        one_hour    => 3600,
        one_day     => 86_400,
        one_week    => 604_800,
        one_year    => 31_536_000
    };
}

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

    # If there is a max age for the browser to have,
    # set the header
    my $browser_max_age = $c->browser_max_age;
    if ( defined $browser_max_age ) {
        $c->res->header( 'Cache-Control' => 'max-age=' . $browser_max_age );
    }

    # Some action must have triggered a purge
    if ( $c->has_surrogate_keys_to_purge ) {

        # Something changed, means we need to purge some keys
        # All keys are set as UC, with : and -'s removed
        # so make sure our purging is as well
        my @keys = map {
            $_ =~ s/://g;    #
            $_ =~ s/-//g;    #
            uc $_            #
        } $c->surrogate_keys_to_purge();

        $c->cdn_purge_now(
            {
                keys => \@keys,
            }
        );
    }

    # Surrogate key caching and purging
    if ( $c->has_surrogate_keys ) {

        # See http://www.fastly.com/blog/surrogate-keys-part-1/
        # Force all keys to uc, and remove :'s and -'s for consistency
        my $key = uc $c->join_surrogate_keys(' ');
        $key =~ s/://g;    # FOO::BAR -> FOOBAR
        $key =~ s/-//g;    # FOO-BAR -> FOOBAR
        $c->res->header( 'Surrogate-Key' => $key );
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

sub _cdn_get_service {
    my ( $c, $args ) = @_;

    my $net_fastly = $c->_net_fastly();
    return unless $net_fastly;

    my $fsi = $c->config->{fastly_service_id};
    return $net_fastly->get_service($fsi);

}

=head2 cdn_purge_now

  $c->cdn_purge_now({
    keys => [ 'foo', 'bar' ]
  });

=cut

sub cdn_purge_now {
    my ( $c, $args ) = @_;

    my $service = $c->_cdn_get_service();
    return unless $service;    # dev box

    foreach my $key ( @{ $args->{keys} || [] } ) {
        $service->purge_by_key($key);
    }
}

=head2 cdn_purge_all

  $c->cdn_purge_all()

=cut

sub cdn_purge_all {
    my $c = shift;

    my $fastly_service = $c->_cdn_get_service();
    die "No access" unless $fastly_service;

    $fastly_service->purge_all;
}

1;
