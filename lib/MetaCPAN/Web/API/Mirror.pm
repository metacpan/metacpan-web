package MetaCPAN::Web::API::Mirror;

use Moose;
use namespace::autoclean;
with qw(MetaCPAN::Web::API::Request);

has api => (
    is       => 'ro',
    isa      => 'MetaCPAN::Web::API',
    weak_ref => 1,
);

sub list {
    my ( $self, $location, $protocols ) = @_;

    my @or;
    push( @or, { not => { filter => { missing => { field => $_ } } } } )
        for ( @{ $protocols || [] } );

    return $self->request(
        '/mirror/_search',
        {   size  => 999,
            query => { match_all => {} },
            @or ? ( filter => { and => \@or } ) : (),
            $location
            ? ( sort => {
                    _geo_distance => {
                        location => [ $location->[1], $location->[0] ],
                        order    => "asc",
                        unit     => "km"
                    }
                }
                )
            : ( sort => [ 'continent', 'country' ] )
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
