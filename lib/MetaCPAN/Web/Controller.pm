package MetaCPAN::Web::Controller;
use Moose;
use namespace::autoclean;

use Data::Pageset ();
use List::Util    qw( min );

BEGIN { extends 'Catalyst::Controller'; }

sub pageset {
    my ( $self, $page, $page_size, $total ) = @_;
    return Data::Pageset->new( {
        current_page     => $page,
        entries_per_page => $page_size,
        mode             => 'slide',
        pages_per_set    => 10,
        total_entries    => min( $total // 0, 5000 ),
    } );
}

__PACKAGE__->meta->make_immutable;

1;
