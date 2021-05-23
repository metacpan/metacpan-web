package MetaCPAN::Web::Controller::Pod;

use Moose;

use Future;
use MetaCPAN::Web::RenderUtil qw( filter_html );
use Try::Tiny qw( try );

use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# /pod/$name
sub find : Path : Args(1) {
    my ( $self, $c, @path ) = @_;

    $c->browser_max_age('1h');

    # TODO: Pass size param so we can disambiguate?
    my $pod_file = $c->stash->{pod_file}
        = $c->model('API::Module')->find(@path)->get;

    $c->detach('/not_found')
        if !$pod_file->{name};

    my $release_info
        = $c->model('ReleaseInfo')
        ->get( $pod_file->{author}, $pod_file->{release}, $pod_file )
        ->else( sub { Future->done( {} ) } );
    $c->stash( $release_info->get );

    # TODO: Disambiguate if there's more than one match. #176

    $c->forward( 'view', [@path] );
}

# /pod/release/$AUTHOR/$release/@path
sub release : Local : Args {
    my ( $self, $c, $author, $release, @path ) = @_;

    if ( !@path ) {
        $c->detach('/not_found');
    }
    $c->browser_max_age('1d');

    # force consistent casing in URLs
    if ( $author ne uc $author ) {
        $c->res->redirect(
            $c->uri_for( $c->action, uc $author, $release, @path ), 301 );
        $c->detach();
    }

    my $pod_file
        = $c->model('API::Module')->get( $author, $release, @path )->get;
    my $release_data
        = $c->model('ReleaseInfo')->get( $author, $release, $pod_file )
        ->else_done( {} );
    $c->stash( {
        pod_file => $pod_file,
        %{ $release_data->get },
        permalinks => 1,
    } );

    $c->forward( 'view', [ $author, $release, @path ] );
}

# /pod/distribution/$name/@path
sub distribution : Local : Args {
    my ( $self, $c, $dist, @path ) = @_;

    $c->browser_max_age('1h');

    $c->detach('/not_found')
        if !defined $dist || !@path;

# TODO: Could we do this with one query?
# filter => { path => join('/', @path), distribution => $dist, status => latest }

    # Get latest "author/release" of dist so we can use it to find the file.
    # TODO: Pass size param so we can disambiguate?
    my $release_data = try {
        $c->model('ReleaseInfo')->find($dist)->get;
    } or $c->detach('/not_found');

    unshift @path, @{ $release_data->{release} }{qw( author name )};

    $c->stash( {
        %$release_data, pod_file => $c->model('API::Module')->get(@path)->get,
    } );

    $c->forward( 'view', [@path] );
}

sub view : Private {
    my ( $self, $c, @path ) = @_;

    my $data       = $c->stash->{pod_file};
    my $permalinks = $c->stash->{permalinks};

    if ( $data->{directory} ) {
        $c->res->redirect( $c->uri_for( '/source', @path ), 301 );
        $c->detach;
    }

    my ( $documentation, $assoc_pod, $documented_module )
        = map { $_->{name}, $_->{associated_pod}, $_ }
        grep  { @path > 1 || $path[0] eq $_->{name} }
        grep {
              !$data->{documentation}
            || $data->{documentation} eq $_->{name}
        }
        grep { $_->{associated_pod} } @{ $data->{module} || [] };

    $data->{documentation} = $documentation if $documentation;

    if (   $assoc_pod
        && $assoc_pod ne "$data->{author}/$data->{release}/$data->{path}" )
    {
        $data->{pod_path}
            = $assoc_pod =~ s{^\Q$data->{author}/$data->{release}/}{}r;
    }

    $c->detach('/not_found') unless ( $data->{name} );

    my $pod_path = '/pod/' . ( $assoc_pod || join( q{/}, @path ) );

    my $pod = $c->model('API')->request(
        $pod_path,
        undef,
        {
            show_errors => 1,
            ( $permalinks ? ( permalinks => 1 ) : () ),
            url_prefix => '/pod/',
        }
    )->get;
    $c->detach('/not_found') if ( $pod->{code} || 0 ) > 399;

    my $pod_html = filter_html( $pod->{raw}, $data );

    my $release = $c->stash->{release};

    my $canonical
        = (    $documented_module
            && $documented_module->{authorized}
            && $documented_module->{indexed} )
        ? "/pod/$documentation"
        : "/pod/distribution/$release->{distribution}/$data->{path}";

    # Store at fastly for a year - as we will purge!
    $c->cdn_max_age('1y');
    $c->add_dist_key( $release->{distribution} );
    $c->add_author_key( $release->{author} );

    $c->stash( {
        canonical         => $canonical,
        documented_module => $documented_module,
        module            => $data,
        pod               => $pod_html,
        template          => 'pod.tx',
    } );

    unless ( $pod->{raw} ) {
        $c->stash( pod_error => $pod->{message}, );
    }
}

__PACKAGE__->meta->make_immutable;

1;
