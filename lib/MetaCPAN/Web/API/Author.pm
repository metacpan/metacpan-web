package MetaCPAN::Web::API::Author;

use Moose;
use namespace::autoclean;
with qw(MetaCPAN::Web::API::Request);

has api => (
    is       => 'ro',
    isa      => 'MetaCPAN::Web::API',
    weak_ref => 1,
);

sub get {
    my ( $self, $author ) = @_;
    $self->request( "/author/" . uc($author) );
}

__PACKAGE__->meta->make_immutable;

1;
