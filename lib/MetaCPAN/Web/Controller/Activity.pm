package MetaCPAN::Web::Controller::Activity;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use DateTime;

sub author : Chained('/author/root') PathPart('activity.svg') Args(0) {
    my ( $self, $c ) = @_;
    my $author = $c->stash->{pauseid};

    $c->forward( 'activity', [ author => $author ] );
}

sub dist : Chained('/dist/root') PathPart('activity.svg') Args(0) {
    my ( $self, $c ) = @_;
    my $dist = $c->stash->{distribution_name};

    $c->forward( 'activity', [ distribution => $dist ] );
}

sub module : Chained('/module/root') PathPart('activity.svg') Args(0) {
    my ( $self, $c ) = @_;
    my $module = $c->stash->{module_name};

    $c->forward( 'activity', [ module => $module ] );
}

sub releases : Path('releases.svg') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward('activity');
}

sub distributions : Path('distributions.svg') Args(0) {
    my ( $self, $c ) = @_;

    $c->forward( 'activity', [ new_dists => 'n' ] );
}

sub activity : Private {
    my ( $self, $c, %args ) = @_;

    my $params = $c->req->parameters;
    $args{res} = $params->{res}
        if $params->{res};

    my $line = $c->model('API')->request( '/activity', undef, \%args )->get;
    return unless $line and exists $line->{activity};

    $c->res->content_type('image/svg+xml');
    $c->res->headers->expires( time + 86400 );
    $c->stash( {
        data     => $line->{activity},
        template => 'activity.svg.tx',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
