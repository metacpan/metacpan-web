package MetaCPAN::Web::Model::API::Author;

use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

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
    my ( $self, @author ) = @_;

    return $self->request( '/author/' . uc( $author[0] ) )
        if ( @author == 1 );

    return $self->request( '/author/by_id', undef, { id => \@author } );
}

sub search {
    my ( $self, $query, $from ) = @_;
    my $cv = $self->cv;
    $from ||= 0;
    $self->request( '/author/by_key', undef,
        { key => $query, from => $from, size => 10 } )->cb(
        sub {
            my $results = shift->recv;
            $cv->send($results);
        }
        );
    return $cv;
}

sub by_user {
    my ( $self, $users ) = @_;
    return $self->request( '/author/by_user', undef,
        { fields => [qw<user pauseid>], user => $users } );
}

__PACKAGE__->meta->make_immutable;

1;
