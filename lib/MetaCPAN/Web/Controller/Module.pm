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
        supplanted_by => {
            'Foo'       => 3,
            'Bar::Baz'  => 2,
        },
        instead_use => {
            'Frob::Uscate' => 4,
        },
    };

=cut

sub groom_recommendations {
    my( $self, $c, $data ) = @_;

    $DB::single = 1;
    
    my $r = $data->{recommendations} or return [];

    my %rec;

    if ( my $plus = $r->{instead_of} ) {
        while( my ($module,$votes) = each %$plus ) {
            $rec{$module}{module} = $module;
            $rec{$module}{score} = $rec{$module}{plus} = $votes;
        }
    }

    if ( my $minus = $r->{supplanted_by} ) {
        while( my ($module,$votes) = each %$minus ) {
            $rec{$module}{module} = $module;
            $rec{$module}{minus} = $votes;
            $rec{$module}{score} -= $votes;
        }
    }

    return [
        sort { $a->{score} <=> $b->{score} } values %rec
    ];

}

1;
