package MetaCPAN::Web::Model::API::Contributors;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

=head1 NAME

MetaCPAN::Web::Model::Contributors - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Graham Knop

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub get {
    my ( $self, $author, $release ) = @_;
    my $cv = $self->cv;

    $self->request( '/release/contributors/' . $author . '/' . $release,
        )->cb(
        sub {
            my ($contributors) = shift->recv;
            $cv->send( $contributors->{contributors} );
        }
        );
    return $cv;
}

__PACKAGE__->meta->make_immutable;

1;
