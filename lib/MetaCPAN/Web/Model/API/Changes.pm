package MetaCPAN::Web::Model::API::Changes;
use Moose;
extends 'MetaCPAN::Web::Model::API';

use CPAN::Changes;
use Try::Tiny;

sub get {
    my ( $self, @path ) = @_;
    $self->request( '/changes/' . join( '/', @path ) );
}

sub last_version {
    my ( $self, $response ) = @_;
    my $changes;
    if ( !exists $response->{content} or $response->{documentation} ) {
    } else {
        # I guess we have a propper changes file? :P
        try {
            $changes = CPAN::Changes->load_string($response->{content});
        } catch {
            # we don't really care?
            warn "Error parsing changes: $_";
        };
    }
    return unless $changes;
    my @releases = $changes->releases;
    return unless scalar @releases;
    return $releases[-1];
}
1;
