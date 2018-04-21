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

    # If there's no release, we'll just redirect
    $release //= {};

    $self->request( '/release/contributors/' . $author . '/' . $release, )
        ->transform(
        done => sub {
            my $data = shift;
            return $data->{contributors};
        }
        );
}

sub unique_dists_by_pauseid {
    my ( $self, $pauseid ) = @_;

    $self->request( '/contributor/by_pauseid/' . $pauseid )->transform(
        done => sub {
            my $data = shift;
            my %dists = map { $_->{distribution} => $_->{author} }
                @{ $data->{contributors} };
            return [
                map +{ distribution => $_, author => $dists{$_} },
                sort keys %dists
            ];
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
