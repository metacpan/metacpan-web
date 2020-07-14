package MetaCPAN::Web::Controller::Mirrors;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(0) {
    my ( $self, $c ) = @_;

    $c->add_surrogate_key('MIRRORS');
    $c->add_surrogate_key('STATIC');
    $c->browser_max_age('1d');
    $c->cdn_max_age('1d');

    my $query  = join( q{ }, $c->req->param('q') );
    my @protos = $query =~ /(\S+)/g;
    my $data   = $c->model('API::Mirror')->search($query)->get;

    $c->stash( {
        mirrors      => $data->{mirrors},
        took         => $data->{took},
        total        => $data->{total},
        search_query => $query,
        protocols    => \@protos,
        template     => 'mirrors.html',
    } );
}

__PACKAGE__->meta->make_immutable;

1;
