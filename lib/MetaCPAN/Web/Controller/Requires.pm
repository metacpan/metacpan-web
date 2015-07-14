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

    my $page_size = $c->req->get_page_size(50);

    my $data
        = $c->model('API::Release')
        ->reverse_dependencies( $distribution, $c->req->page, $page_size,
        $sort )->get;
    $c->stash(
        {
            %{$data},
            type_of_required => 'distribution',
            required         => $distribution,
            page_size        => $page_size,
            template         => 'requires.html'
        }
    );
}

sub module : Local : Args(1) : Does('Sortable') {
    my ( $self, $c, $module, $sort ) = @_;

    my $page_size = $c->req->get_page_size(50);

    my $data
        = $c->model('API::Module')
        ->requires( $module, $c->req->page, $page_size, $sort );
    $c->stash(
        {
            %{$data},
            type_of_required => 'module',
            required         => $module,
            page_size        => $page_size,
            template         => 'requires.html'
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
