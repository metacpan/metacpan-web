package MetaCPAN::Web::Controller::Activity;

use Moose;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use DateTime;

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    my %args = map { $_ => $c->req->parameters->{$_} }
        keys %{ $c->req->parameters };
    my $line = $c->model('API')->request( '/activity', undef, \%args )->get;
    return unless $line and exists $line->{activity};

    $c->res->content_type('image/svg+xml');
    $c->res->headers->expires( time + 86400 );
    $c->stash( {
        data     => $line->{activity},
        template => 'activity.xml',
        color    => $args{color} || '#36C'
    } );
    $c->detach('View::Raw');
}

__PACKAGE__->meta->make_immutable;

1;
