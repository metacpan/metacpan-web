package MetaCPAN::Web::Controller::Pod;

use Moose;

use Future ();

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# /pod/$name
sub find : Path : Args(1) {
    my ( $self, $c, @path ) = @_;

    $c->browser_max_age('1h');

    # TODO: Pass size param so we can disambiguate?
    my $pod_file = $c->stash->{file}
        = $c->model('API::Module')->find(@path)->get;

    $c->detach('/not_found')
        if !$pod_file->{name};

    my $release_info
        = $c->model('ReleaseInfo')
        ->get( $pod_file->{author}, $pod_file->{release} )
        ->else( sub { Future->done( {} ) } );
    $c->stash( $release_info->get );

    # TODO: Disambiguate if there's more than one match. #176

    $c->forward( '/view/file', [@path] );
}

sub view : Private {
    my ( $self, $c, @path ) = @_;

    my $data       = $c->stash->{file};
    my $permalinks = $c->stash->{permalinks};
    my $release    = $c->stash->{release};

    if ( $data->{directory} ) {

# This can end up being a redirect from a non-versioned path to a versioned path
# and it doesn't have any surrogate keys so it won't get purged.
        $c->cdn_max_age('1d');
        $c->res->redirect( $c->uri_for( '/source', @path ), 301 );
        $c->detach;
    }

    $c->detach('/not_found')
        unless $data->{name};

    my $documented_module = $data->{documented_module};

    my $canonical
        = (    $documented_module
            && $documented_module->{authorized}
            && $documented_module->{indexed} )
        ? "/pod/$data->{documentation}"
        : "/dist/$release->{distribution}/view/$data->{path}";

    my $pod = $c->model('API::Pod')->file_pod(
        $data,
        {
            permalinks => $permalinks,
        }
    )->get;

    $c->detach('/not_found')
        if ( $pod->{code} || 0 ) > 399;

    if ( $data->{deprecated} ) {
        $c->stash->{notification} ||= { type => 'MODULE_DEPRECATED' };
    }

    $c->stash( {
        canonical         => $canonical,
        documented_module => $documented_module,
        pod               => $pod->{pod_html},
        pod_index         => $pod->{pod_index},
        template          => 'pod.tx',
    } );

    unless ( $pod->{raw} ) {
        $c->stash( pod_error => $pod->{message} );
    }
}

__PACKAGE__->meta->make_immutable;

1;
