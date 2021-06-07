package MetaCPAN::Web::Controller::Dist;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub root : Chained('/') PathPart('dist') CaptureArgs(1) {
    my ( $self, $c, $dist ) = @_;
    $c->stash( { distribution_name => $dist } );
}

sub dist_view : Chained('root') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    my $dist = $c->stash->{distribution_name};

    $c->stash( release_info =>
            $c->model( 'ReleaseInfo', full_details => 1 )->find($dist) );
    $c->forward('/release/view');
}

sub plussers : Chained('root') PathPart('plussers') Args(0) {
    my ( $self, $c ) = @_;
    my $dist = $c->stash->{distribution_name};
    $c->stash( $c->model('API::Favorite')->find_plussers($dist)->get );
    $c->stash( { template => 'plussers.tx' } );
}

__PACKAGE__->meta->make_immutable;

1;
