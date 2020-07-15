package MetaCPAN::Web::Controller::Requires;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# The order of the columns matters here. It aims to be compatible
# to jQuery tablesorter plugin.
__PACKAGE__->config(
    sort => {
        distribution => {
            columns => [qw(name abstract date)],
            default => [qw(date desc)],
        },
        module => {
            columns => [qw(name abstract date)],
            default => [qw(date desc)],
        }
    }
);

sub distribution : Local : Args(1) : Does('Sortable') {
    my ( $self, $c, $distribution, $sort ) = @_;

    my $page      = $c->req->page;
    my $page_size = $c->req->get_page_size(50);

    my $data
        = $c->model('API::Release')
        ->reverse_dependencies( $distribution, $page, $page_size, $sort )
        ->get;

    my $pageset = Data::Pageset->new( {
        current_page     => $page,
        entries_per_page => $page_size,
        mode             => 'slide',
        pages_per_set    => 10,
        total_entries    => $data->{total},
    } );

    $c->stash( {
        %{$data},
        type_of_required => 'distribution',
        required         => $distribution,
        pageset          => $pageset,
        template         => 'requires.html'
    } );
}

sub module : Local : Args(1) : Does('Sortable') {
    my ( $self, $c, $module, $sort ) = @_;

    my $page      = $c->req->page;
    my $page_size = $c->req->get_page_size(50);

    my $data
        = $c->model('API::Module')
        ->requires( $module, $page, $page_size, $sort )->get;

    my $pageset = Data::Pageset->new( {
        current_page     => $page,
        entries_per_page => $page_size,
        mode             => 'slide',
        pages_per_set    => 10,
        total_entries    => $data->{total},
    } );

    $c->stash( {
        %{$data},
        type_of_required => 'module',
        required         => $module,
        pageset          => $pageset,
        template         => 'requires.html'
    } );
}

__PACKAGE__->meta->make_immutable;

1;
