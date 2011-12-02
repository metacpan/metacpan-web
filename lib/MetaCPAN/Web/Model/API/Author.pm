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
    my ( $self, $author ) = @_;
    $self->request( "/author/" . uc($author) );

}

sub search {
    my ( $self, $query, $from ) = @_;

    my $cv     = $self->cv;
    my $search = {
        query => {
            bool => {
                should => [
                    {   text => {
                            'author.name.analyzed' =>
                                { query => $query, operator => 'and' }
                        }
                    },
                    { text => { 'author.pauseid'    => uc($query) } },
                    { text => { 'author.profile.id' => lc($query) } },
                ]
            }
        },
        size => 10,
        from => $from || 0,
    };

    $self->request( '/author/_search', $search )->cb(
        sub {
            my $results = shift->recv
                || { hits => { total => 0, hits => [] } };
            $cv->send(
                {   results => [
                        map { +{ %{ $_->{_source} }, id => $_->{_id} } }
                            @{ $results->{hits}{hits} }
                    ],
                    total => $results->{hits}{total} || 0,
                    took => $results->{took}
                }
            );
        }
    );
    return $cv;
}

__PACKAGE__->meta->make_immutable;

1;
