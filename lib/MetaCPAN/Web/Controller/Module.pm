package MetaCPAN::Web::Controller::Module;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

# NOTE: We may (be able to) put these redirects into nginx
# but it's nice to have them here (additionally) for development.

sub redirect_to_pod : Path : Args {
    my ( $self, $c, @path ) = @_;

    # Forward old '/module/' links to the new '/pod/' controller.
    $c->cdn_max_age('1y');

    # /module/AUTHOR/Release-0.0/lib/Foo/Bar.pm
    if ( @path > 1 ) {

        # Force the author arg to uppercase to avoid another redirect.
        $c->res->redirect(
            $c->uri_for( '/pod/release', uc( shift @path ), @path ), 301 );
    }

    # /module/Foo::Bar
    else {
        $c->res->redirect( $c->uri_for( '/pod', @path ), 301 );
    }

    $c->detach();
}

__PACKAGE__->meta->make_immutable;

1;
