package MetaCPAN::Web::Controller::Lab;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# The order of the columns matters here. It aims to be compatible
# to jQuery tablesorter plugin.
__PACKAGE__->config(
    sort => {
        dependencies => {
            columns => [qw(name abstract date)],
            default => [qw(date desc)],
        }
    }
);

sub lab : Path : Args(0) {
    my ( $self, $c ) = @_;
    $c->res->redirect( '/tools', 301 );
    $c->detach;
}

sub dependencies : Local : Args(0) : Does('Sortable') {
    my ( $self, $c ) = @_;

    my $module;
    my $data;

    if ( $module = $c->req->params->{'module'} ) {
        $data = $c->model('API::Lab')->dependencies($module)->get;
    }

    $c->stash( {
        template => 'lab/dependencies.tx',
        module   => $module,
        data     => $data,
    } );
}

sub personal_dashboard : Path('dashboard') : Args(0) {
    my ( $self, $c ) = @_;

    if ( my $pauseid = $c->req->params->{'pauseid'} ) {
        $c->res->redirect( $c->uri_for( '/lab/dashboard', uc $pauseid ),
            301 );
        $c->detach;
    }

    my $user     = $c->user;
    my $pause_id = $user && $user->pause_id;

    $c->res->header( 'Vary', 'Cookie' );
    $c->stash( { personal => 1 } );
    $c->go( 'dashboard', [ $pause_id || () ] );
}

sub dashboard : Local : Args(1) {
    my ( $self, $c, $pauseid ) = @_;

    my $report;
    if ($pauseid) {
        $report = $c->model('API::Lab')->fetch_latest_distros( 300, $pauseid )
            ->get;
    }

    $c->stash( {
        pauseid  => $pauseid,
        report   => $report,
        template => 'lab/dashboard.tx',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
