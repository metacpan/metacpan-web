package MetaCPAN::Web::Controller::River;
use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub root : Chained('/') PathPart('river') CaptureArgs(0) { }

sub gauge : Chained('root') PathPart('gauge') Args(1) {
    my ( $self, $c, $name ) = @_;

    my $dist = $c->model('API::Distribution')->get($name)->get;

    # Lack of river data for a dist is handled differently in the template.
    $c->detach('/not_found')
        unless $dist->{name};

    $c->res->content_type('image/svg+xml');
    $c->stash(
        {
            distribution => $dist,
            template     => 'river/gauge.svg',
        }
    );
    $c->detach( $c->view("Raw") );
}

__PACKAGE__->meta->make_immutable;

1;
