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


sub lab : Local : Path('/lab') {
    my ( $self, $c ) = @_;
    $c->stash( template => 'lab.html' );
}

sub index : Chained('/') : PathPart('lab') : CaptureArgs(0) { }

#sub dependencies : Chained('index') : PathPart : Args(1) : Does('Sortable') {
sub dependencies : Chained('index') : PathPart : Does('Sortable') {
    my ( $self, $c ) = @_;
	my $module = $c->req->params->{'module'};
   
    my $data
        = $c->model('API::Lab')->dependencies( $module );

    $c->stash( { template => 'lab/dependencies.html', module => $module, data => $data } );
}

sub dashboard : Chained('index') : PathPart {
    my ( $self, $c ) = @_;
    my $author = $c->model('API::User')->get_profile( $c->token )->recv;

    my $pauseid = $author->{pauseid};
    my $data;
    if ($pauseid) {
        $data = $c->model('API::Lab')->fetch_latest_distros(1000, $pauseid);
    }

    $c->stash( {
        template => 'lab/dashboard.html',
        author   => $author,
        pauseid  => $pauseid,
        report   => $data,
    } );
}
1;

