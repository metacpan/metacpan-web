package MetaCPAN::Web::Model::API::Distribution;
use Moose;
extends 'MetaCPAN::Web::Model::API';

sub get {
    my ( $self, $dist ) = @_;
    $self->request("/distribution/$dist")->then( sub {
        my $data = shift;
        Future->done( {
            distribution => $data,
        } );
    } );
}

__PACKAGE__->meta->make_immutable;

1;
