package MetaCPAN::Web::Role::Fastly;

use Moose::Role;
use Net::Fastly;

with 'CatalystX::Fastly::Role::Response';

use MetaCPAN::Web::Types qw(:all);

=head1 NAME

MetaCPAN::Web::Role::Fastly - Methods for fastly intergration

=head1 METHODS

=head2 $c->purge_surrogate_key('BAR');

=cut

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

sub datacenters {
    my ($c) = @_;
    my $net_fastly = $c->_net_fastly();
    return unless $net_fastly;

    # Uses the private interface as fastly client doesn't
    # have this end point yet
    my $datacenters = $net_fastly->client->_get('/datacenters');
    return $datacenters;
}




sub fastly_magic {
    my $c = shift;


    # Some action must have triggered a purge
    if ( $c->has_surrogate_keys_to_purge ) {

        # Something changed, means we need to purge some keys
        # All keys are set as UC, with : and -'s removed
        # so make sure our purging is as well
        my @keys = map {
            my $k = uc $_;    #
            $k =~ s/://g;     #
            $k =~ s/-//g;     #
            $k                #
        } $c->surrogate_keys_to_purge();

        $c->cdn_purge_now(
            {
                keys => \@keys,
            }
        );
    }

    # Surrogate key caching and purging
    # if ( $c->has_surrogate_keys ) {

    #     # See http://www.fastly.com/blog/surrogate-keys-part-1/
    #     # Force all keys to uc, and remove :'s and -'s for consistency
    #     my $key = uc $c->join_surrogate_keys(' ');
    #     $key =~ s/://g;    # FOO::BAR -> FOOBAR
    #     $key =~ s/-//g;    # FOO-BAR -> FOOBAR
    #     $c->res->header( 'Surrogate-Key' => $key );
    # }

}

1;
