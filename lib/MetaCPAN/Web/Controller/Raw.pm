package MetaCPAN::Web::Controller::Raw;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('raw') : Chained('/') : Args {
    my ( $self, $c, @module ) = @_;

    my ( $source, $module ) = (
        $c->model('API::Module')->source(@module)->recv,
        $c->model('API::Module')->get(@module)->recv
    );
    $c->detach('/not_found') unless ( $source->{raw} );
    if ( $c->req->parameters->{download} ) {
        my $content_disposition = 'attachment';
        if ( my $filename = $module->{name} ) {
            $content_disposition .= "; filename=$filename";
        }
        $c->res->body( $source->{raw} );
        $c->res->content_type('text/plain');
        $c->res->header( 'Content-Disposition' => $content_disposition );
    }
    else {
        $c->stash(
            {
                source   => $source->{raw},
                module   => $module,
                template => 'raw.html'
            }
        );
    }
}

1;
