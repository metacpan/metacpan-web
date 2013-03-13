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

=pod

For giggles and to get the ball running, I'm assuming that recommendations are per-modules.

I'm also assuming that we have the modules recommended over this one, and
those under it. And that the whole this has the format:

    $data->{recommendations} = {
        recommended_over => {
            'Foo'       => [ 'AUTHOR1', 'AUTHOR2' ],
            'Bar::Baz'  => [ 'AUTHOR3' ],
        },
        rather_use => {
            'Frob::Uscate' => [ 'AUTHOR4' ],
        },
    };

Yes, 'rather_use' is a crappy key, but for now it'll do. We'll s/// it to
something decent down the line.

=cut

sub groom_recommendations {
    my( $self, $c, $data ) = @_;

    # sample data
    $data->{recommendations} = {
        recommended_over => {
            'Foo'       => [ 'AUTHOR1', 'AUTHOR2' ],
            'Bar::Baz'  => [ 'AUTHOR3' ],
            'Frob::Uscate' => [ 'AUTHOR5', 'AUTHOR6' ],
        },
        rather_use => {
            'Frob::Uscate' => [ 'AUTHOR4' ],
        },
    };

    my $r = $data->{recommendations} or return [];

    my %rec;

    if ( my $plus = $r->{recommended_over} ) {
        while( my ($module,$votes) = each %$plus ) {
            $rec{$module}{module} = $module;
            $rec{$module}{sum} = $rec{$module}{plus} = scalar @$votes;
        }
    }

    if ( my $minus = $r->{rather_use} ) {
        while( my ($module,$votes) = each %$minus ) {
            $rec{$module}{module} = $module;
            $rec{$module}{minus} = scalar @$votes;
            $rec{$module}{sum}  += scalar @$votes;
        }
    }

    return [
        reverse sort { $a->{sum} <=> $b->{sum} } values %rec
    ];

}

1;
