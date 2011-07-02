package MetaCPAN::Web::Model::Author;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';
with 'MetaCPAN::Web::Roles::ES';

=head1 NAME

MetaCPAN::Web::Model::Author - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub get {
    my ( $self, $author ) = @_;
    $self->request( "/author/" . uc($author) );

}

__PACKAGE__->meta->make_immutable;

1;
