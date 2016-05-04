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
    $c->stash( template => 'lab.html' );
}

sub dependencies : Local : Args(0) : Does('Sortable') {
    my ( $self, $c ) = @_;

    my $module;
    my $data;

    if ( $module = $c->req->params->{'module'} ) {
        $data = $c->model('API::Lab')->dependencies($module);
    }

    $c->stash(
        {
            template => 'lab/dependencies.html',
            module   => $module,
            data     => $data
        }
    );
}

sub dashboard : Local : Args(0) {
    my ( $self, $c ) = @_;

    my $user = $c->model('API::User')->get_profile( $c->token )->recv;

    my $report;
    my $pauseid = $c->req->params->{'pauseid'};
    if ($pauseid) {
        $user = { pauseid => $pauseid };
    }

    if ($user) {
        $pauseid = $user->{pauseid};
        if ($pauseid) {
            $report = $c->model('API::Lab')
                ->fetch_latest_distros( 1000, $pauseid );
        }
    }

    $report->{user} = $user;

    $c->stash(
        {
            template => 'lab/dashboard.html',
            pauseid  => $pauseid,
            report   => $report,
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
