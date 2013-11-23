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

1;

