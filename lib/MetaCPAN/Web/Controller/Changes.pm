package MetaCPAN::Web::Controller::Changes;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub distribution : Local Args(1) {
    my ( $self, $c, $distribution ) = @_;

    $c->forward( 'get', [$distribution] );
}

sub release : Local Args(2) {
    my ( $self, $c, $author, $release ) = @_;

    # force consistent casing in URLs
    if ( $author ne uc($author) ) {
        $c->res->redirect(
            $c->uri_for( $c->action, [ uc($author), $release ] ), 301 );
        $c->detach();
    }

    $c->forward( 'get', [ $author, $release ] );
}

sub get : Private {
    my ( $self, $c, @args ) = @_;

    my $file = $c->model('API::Changes')->get(@args)->recv;

    # NOTE: There is currently no differentiation (from the API)
    # of whether the release doesn't exist or we couldn't find a change log.
    # We don't care about the difference here either.
    if ( !exists $file->{content} ) {

        my $release = join( q{/}, @args );
        my $suggest = {
            description => 'Try the release info page',

            # Is there a more Catalyst way to do this?
            url       => $c->uri_for( '/release/' . $release ),
            link_text => $release,
        };

        $c->stash(
            {
                message => 'Change log not found for release.',
                suggest => $suggest,
            }
        );
        $c->detach('/not_found');
    }

    # display as pod if it is a pod file (perldelta.pod and some other dists)
    elsif ( $file->{documentation} ) {

        # Is there a better way to reuse the pod view?
        $c->forward( '/pod/release', [ @$file{qw( author release path )} ] );
    }
    else {
        $c->stash( { file => $file } );
        $c->forward('/source/content');
    }
}

1;
