package MetaCPAN::Web::Controller::View;

use Moose;
use experimental 'postderef';
use namespace::autoclean;
use Try::Tiny qw( try );

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub dist : Chained('/dist/root') PathPart('view') Args {
    my ( $self, $c, @path ) = @_;
    my $dist = $c->stash->{distribution_name};

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
        %$release_data, file => $c->model('API::File')->get(@path)->get,
    } );

    $c->forward( 'file', [@path] );
}

sub release : Chained('/release/root') PathPart('view') Args {
    my ( $self, $c, @path ) = @_;
    my ( $author, $release ) = $c->stash->@{qw(author_name release_name)};

    if ( !@path ) {
        $c->detach('/not_found');
    }
    $c->browser_max_age('1d');

    my $file = $c->model('API::File')->get( $author, $release, @path )->get;
    my $release_data
        = $c->model('ReleaseInfo')->get( $author, $release )->else_done( {} );
    $c->stash( {
        file => $file,
        %{ $release_data->get },
        permalinks => 1,
    } );

    $c->forward( 'file', [ $author, $release, @path ] );
}

sub file : Private {
    my ( $self, $c, @path ) = @_;

    my $release = $c->stash->{release};
    my $file    = $c->stash->{file};

    $c->cdn_max_age('1y');
    $c->add_dist_key( $release->{distribution} );
    $c->add_author_key( $release->{author} );

    if (   $file->{mime} eq 'text/x-script.perl'
        || $file->{mime} eq 'text/x-script.perl-module'
        || $file->{mime} eq 'text/x-pod' )
    {
        $c->forward( '/pod/view', \@path );
    }
    elsif ( $file->{mime} eq 'text/markdown' ) {
        $c->forward( '/md/view', \@path );
    }
    else {
        $c->forward( '/source/view', \@path );
    }
}

__PACKAGE__->meta->make_immutable;

1;
