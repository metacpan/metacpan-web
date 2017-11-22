package MetaCPAN::Web::Model::API::Diff;
use Moose;
use namespace::autoclean;
use Digest::SHA;

extends 'MetaCPAN::Web::Model::API';

sub releases {
    my ( $self, @path ) = @_;
    return $self->request( '/diff/release/' . join( q{/}, @path ) );
}

sub files {
    my ( $self, $source, $target ) = @_;
    my @source = split( /\//, $source );
    $source
        = $self->digest( shift @source, shift @source,
        join( q{/}, @source ) );
    my @target = split( /\//, $target );
    $target
        = $self->digest( shift @target, shift @target,
        join( q{/}, @target ) );
    return $self->request( '/diff/file/' . join( q{/}, $source, $target ) );
}

sub digest {
    my $self = shift;
    my $digest = Digest::SHA::sha1_base64( join( "\0", grep {defined} @_ ) );
    $digest =~ tr/[+\/]/-_/;
    return $digest;
}

__PACKAGE__->meta->make_immutable;

1;
