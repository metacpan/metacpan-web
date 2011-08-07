package MetaCPAN::Web::API::Diff;

use Moose;
use Digest::SHA1;
use namespace::autoclean;
with qw(MetaCPAN::Web::API::Request);

has api => (
    is       => 'ro',
    isa      => 'MetaCPAN::Web::API',
    weak_ref => 1,
);

sub releases {
    my ($self, @path) = @_;
    return $self->request('/diff/release/' . join('/', @path));
}

sub files {
    my ($self, $source, $target) = @_;
    my @source = split(/\//, $source);
    $source = $self->digest(shift @source, shift @source, join("/",@source));
    my @target = split(/\//, $target);
    $target = $self->digest(shift @target, shift @target, join("/",@target));
    return $self->request('/diff/file/' . join('/', $source, $target));
}

sub digest {
    my $self = shift;
    my $digest = Digest::SHA1::sha1_base64(join("\0", grep { defined } @_));
    $digest =~ tr/[+\/]/-_/;
    return $digest;
}

__PACKAGE__->meta->make_immutable;

1;
