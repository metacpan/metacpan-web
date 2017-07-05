package MetaCPAN::Web::Controller::Mirrors;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('MIRRORS');
    $c->browser_max_age('1d');
    $c->cdn_max_age('1d');

    my $query = $c->req->parameters->{'q'};
    my $data  = $c->model('API::Mirror')->search($query)->get;

    $c->stash(
        {
            mirrors  => $data->{mirrors},
            took     => $data->{took},
            total    => $data->{total},
            template => 'mirrors.html',
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
