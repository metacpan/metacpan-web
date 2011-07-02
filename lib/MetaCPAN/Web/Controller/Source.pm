package MetaCPAN::Web::Controller::Source;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('source') : Chained('/') : Args {
    my ( $self, $c, @module ) = @_;
    my ( $source, $module )
        = ( $c->model('API::Module')->source(@module)
            & $c->model('API::Module')->get(@module) )->recv;
    if ( $source->{raw} ) {
        $c->stash(
            {   template => 'source.html',
                source   => $source->{raw},
                module   => $module,
            }
        );
    }
    else {
        $c->detach('/not_found');
    }
}

1;
