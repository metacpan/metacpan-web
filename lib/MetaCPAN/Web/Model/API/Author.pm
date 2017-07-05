package MetaCPAN::Web::Model::API::Author;

use Moose;
use namespace::autoclean;

use Ref::Util qw( is_arrayref );

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

    return $self->request( '/author/by_ids', { id => \@author } );
}

sub search {
    my ( $self, $query, $from ) = @_;
    return $self->request( '/author/search', undef,
        { q => $query, from => $from } );
}

sub by_user {
    my ( $self, $users ) = @_;
    return [] unless $users;

    my $ret;
    if ( is_arrayref($users) ) {
        return unless @{$users};
        $ret = $self->request( '/author/by_user', undef, { user => $users } );
    }
    else {
        $ret = $self->request("/author/by_user/$users");
    }
    $ret->transform(
        done => sub {
            return exists $_[0]->{authors} ? $_[0]->{authors} : [];
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
