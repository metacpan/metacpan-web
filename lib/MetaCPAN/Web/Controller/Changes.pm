package MetaCPAN::Web::Controller::Changes;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub distribution : Chained('/dist/root') PathPart('changes') Args(0) {
    my ( $self, $c ) = @_;
    my $dist = $c->stash->{distribution_name};

    $c->forward( 'get', [$dist] );
}

sub release : Chained('/release/root') PathPart('changes') Args(0) {
    my ( $self,   $c )       = @_;
    my ( $author, $release ) = $c->stash->@{qw(author_name release_name)};

    $c->forward( 'get', [ $author, $release ] );
}

sub get : Private {
    my ( $self, $c, @args ) = @_;

    my $file = $c->model('API::Changes')->get(@args)->get;

    # NOTE: There is currently no differentiation (from the API)
    # of whether the release doesn't exist or we couldn't find a change log.
    # We don't care about the difference here either.
    if ( !exists $file->{content} ) {

        my $release = join( q{/}, @args );
        my $suggest = {
            description => 'Try the release info page',

            # Is there a more Catalyst way to do this?
            url => $c->uri_for(
                ( @args == 1 ? '/dist/' : '/release/' ) . $release
            ),
            link_text => $release,
        };

        $c->stash( {
            message => 'Change log not found for release.',
            suggest => $suggest,
        } );
        $c->detach('/not_found');
    }

    # display as pod if it is a pod file (perldelta.pod and some other dists)
    elsif ( $file->{documentation} ) {

        # Is there a better way to reuse the pod view?
        $c->forward( '/view/release', [ $file->{path} ] );
    }
    else {
        $c->stash( { file => $file } );
        $c->forward('/source/content');
    }
}

__PACKAGE__->meta->make_immutable;

1;
