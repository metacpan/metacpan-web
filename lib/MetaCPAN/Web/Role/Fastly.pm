package MetaCPAN::Web::Role::Fastly;

use Moose::Role;
use Net::Fastly;

with 'CatalystX::Fastly::Role::Response';
with 'MooseX::Fastly::Role';

use MetaCPAN::Web::Types qw(:all);

=head1 NAME

MetaCPAN::Web::Role::Fastly - Methods for fastly intergration

=head1 SYNOPSIS

  use Catalyst qw/
    +MetaCPAN::Web::Role::Fastly
    /;

=head1 DESCRIPTION

This role includes L<CatalystX::Fastly::Role::Response> and
L<MooseX::Fastly::Role>.

It also adds some methods.

Finally just before C<finalize> it will add the content type
as surrogate keys and perform a purge of anything needing
to be purged

=head1 METHODS

=head2 $c->purge_surrogate_key('BAR');

=cut

=head2 $c->add_author_key('Ether');

Always upper cases

=cut

sub add_author_key {
    my ( $c, $author ) = @_;

    $author = uc($author);
    $c->add_surrogate_key( 'author=' . $author );
}

=head2 $c->purge_author_key('Ether');

=cut

sub purge_author_key {
    my ( $c, $author ) = @_;
    return unless $author;

    $author = uc($author);
    $c->purge_surrogate_key( 'author=' . $author );
}

=head2 $c->add_dist_key('Moose');

Upper cases, removed I<:> and I<-> so that
Foo::bar and FOO-Bar becomes FOOBAR,
not caring about the edge case of there
ALSO being a Foobar package, they'd
all just get purged.

=cut

sub add_dist_key {
    my ( $c, $dist ) = @_;

    $dist = uc($dist);
    $dist =~ s/:/-/g;    #

    $c->add_surrogate_key( 'dist=' . $dist );
}

=head2 $c->purge_dist_key('Moose');

=cut

sub purge_dist_key {
    my ( $c, $dist ) = @_;

    $dist = uc($dist);
    $dist =~ s/:/-/g;    #

    $c->add_surrogate_key( 'dist=' . $dist );
}

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

before 'finalize' => sub {
    my $c = shift;

    if ( $c->cdn_max_age ) {

        # We've decided to cache on Fastly, so throw fail overs
        # if there is an error at origin
        $c->cdn_stale_if_error('30d');
    }

    my $content_type = lc( $c->res->content_type || 'none' );

    $c->add_surrogate_key( 'content_type=' . $content_type );

    $content_type =~ s/\/.+$//;    # text/html -> 'text'
    $c->add_surrogate_key( 'content_type=' . $content_type );

    # Some action must have triggered a purge
    if ( $c->has_surrogate_keys_to_purge ) {

        # Something changed, means we need to purge some keys
        my @keys = $c->surrogate_keys_to_purge();

        $c->cdn_purge_now( { keys => \@keys, } );
    }

};

=head2 datacenters()

=cut

sub datacenters {
    my ($c) = @_;
    my $net_fastly = $c->cdn_api();
    return unless $net_fastly;

    # Uses the private interface as fastly client doesn't
    # have this end point yet
    my $datacenters = $net_fastly->client->_get('/datacenters');
    return $datacenters;
}

1;
