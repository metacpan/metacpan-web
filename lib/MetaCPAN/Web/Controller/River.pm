package MetaCPAN::Web::Controller::River;
use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub gauge : Chained('/dist/root') PathPart('river.svg') Args(0) {
    my ( $self, $c ) = @_;
    my $dist = $c->stash->{distribution_name};

    my $dist_info = $c->model('API::Distribution')->get($dist)->get;

    # Lack of river data for a dist is handled differently in the template.
    $c->detach('/not_found')
        unless $dist_info->{name};

    $c->res->content_type('image/svg+xml');
    $c->stash( {
        distribution => $dist_info,
        template     => 'river/gauge.svg.tx',
    } );

    $c->cdn_max_age('1y');
    $c->browser_max_age('7d');
    $c->add_dist_key( $dist_info->{name} );
}

__PACKAGE__->meta->make_immutable;

1;
