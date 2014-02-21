package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# NOTE: We may (be able to) put these redirects into nginx
# but it's nice to have them here (additionally) for development.

sub redirect_to_pod : PathPart('module') : Chained('/') : Args {
    my ( $self, $c, @path ) = @_;

    # Forward old '/module/' links to the new '/pod/' controller.

    # /module/AUTHOR/Release-0.0/lib/Foo/Bar.pm
    if ( @path > 1 ) {

        # Force the author arg to uppercase to avoid another redirect.
        $c->res->redirect(
            '/pod/release/' . join( '/', uc( shift @path ), @path ), 301 );
    }

    # /module/Foo::Bar
    else {
        $c->res->redirect( '/pod/' . join( '/', @path ), 301 );
    }

    $c->detach();
}

1;
