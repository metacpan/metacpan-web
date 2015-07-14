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

    return $self->request(
        '/author/_search',
        {
            query => {
                constant_score => {
                    filter => { ids => { values => [ map {uc} @author ] } }
                }
            },
            size => scalar @author,
        }
    );

}

sub search {
    my ( $self, $query, $from ) = @_;

    my $search = {
        query => {
            bool => {
                should => [
                    {
                        match => {
                            'name.analyzed' =>
                                { query => $query, operator => 'and' }
                        }
                    },
                    {
                        match => {
                            'asciiname.analyzed' =>
                                { query => $query, operator => 'and' }
                        }
                    },
                    { match => { 'pauseid'    => uc($query) } },
                    { match => { 'profile.id' => lc($query) } },
                ]
            }
        },
        size => 10,
        from => $from || 0,
    };

    return $self->request( '/author/_search', $search )->transform(
        done => sub {
            my $results = shift
                || { hits => { total => 0, hits => [] } };
            return {
                results => [
                    map { +{ %{ $_->{_source} }, id => $_->{_id} } }
                        @{ $results->{hits}{hits} }
                ],
                total => $results->{hits}{total} || 0,
                took => $results->{took}
            };
        },
    );
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
    return unless $ret;

    my $data = $ret->get;
    return ( exists $data->{authors} ? $data->{authors} : [] );
}

__PACKAGE__->meta->make_immutable;

1;
