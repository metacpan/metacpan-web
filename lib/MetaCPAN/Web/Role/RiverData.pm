package MetaCPAN::Web::Role::RiverData;
use Moose::Role;
use Future;
use List::Util qw( uniq );
use namespace::autoclean;

sub add_river {
    my ( $self, $map ) = @_;
    sub {
        my ($data) = @_;
        my @items = $map ? $map->($data) : @{ $data->{releases} || [] }
            or return Future->done($data);
        my @dists = uniq map $_->{distribution}, @items;
        $self->request(
            '/distribution/river',
            {
                distribution => \@dists,
            }
        )->then( sub {
            my ($river) = @_;
            for my $item (@items) {
                $item->{river}
                    = $river->{river}{ $item->{distribution} } || {};
            }
            Future->done($data);
        } );
    };
}

1;
