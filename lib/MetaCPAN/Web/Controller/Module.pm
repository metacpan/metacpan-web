package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

with qw(
    MetaCPAN::Web::Role::ReleaseInfo
);

sub index : PathPart('module') : Chained('/') : Args {
    my ( $self, $c, @module ) = @_;
    my $data
        = @module == 1
        ? $c->model('API::Module')->find(@module)->recv
        : $c->model('API::Module')->get(@module)->recv;

    $c->detach('/not_found') unless ( $data->{name} );

    my $reqs = $self->api_requests($c, {
            pod     => $c->model('API')->request( '/pod/' . join( '/', @module ) ),
            release => $c->model('API::Release')->get( @{$data}{qw(author release)} ),
        },
        $data,
    );
    $reqs = $self->recv_all($reqs);
    $self->stash_api_results($c, $reqs, $data);
    $self->add_favorites_data($data, $reqs->{favorites}, $data);

    $c->stash(
        {   module  => $data,
            pod     => $reqs->{pod}->{raw},
            release => $reqs->{release}->{hits}->{hits}->[0]->{_source},
            template => 'module.html',
        }
    );
}

1;
