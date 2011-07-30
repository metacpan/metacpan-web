package MetaCPAN::Web::API::Author;

use Moose;
use namespace::autoclean;
with qw(MetaCPAN::Web::API::Request MetaCPAN::Web::API::Ctx);

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
                    { text => { 'author.name.analyzed' => $query } },
                    { text => { 'author.pauseid'       => uc($query) } },
                    { text => { 'author.profile.id'    => lc($query) } },
                ]
            }
        },
        size => 10,
        from => $from || 0,
    };

    $self->request( '/author/_search', $search )->(
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
