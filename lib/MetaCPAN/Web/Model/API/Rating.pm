package MetaCPAN::Web::Model::API::Rating;
use Moose;
use namespace::autoclean;
use Future;

extends 'MetaCPAN::Web::Model::API';

=head1 NAME

MetaCPAN::Web::Model::Rating - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Moritz Onken, Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub get {
    my ( $self, $dist ) = @_;

    return $self->request( '/rating/by_distributions',
        { distribution => $dist } )->then( sub {
        my $data  = shift;
        my $dists = delete $data->{distributions};
        $data->{rating} = $dists->{$dist};
        Future->done($data);
        } );
}

__PACKAGE__->meta->make_immutable;

1;
