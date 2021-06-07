package MetaCPAN::Web::Controller::ContributingDoc;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use List::Util ();

sub dist : Chained('/dist/root') PathPart('contribute') Args(0) {
    my ( $self, $c ) = @_;
    my $dist = $c->stash->{distribution_name};

    my $release = $c->model('API::Release')->find($dist)->get->{release};
    if ( $release && $release->{author} && $release->{name} ) {
        return $c->forward( 'get', [ $release->{author}, $release->{name} ] );
    }
    $c->detach('/not_found');
}

sub release : Chained('/release/root') PathPart('contribute') Args(0) {
    my ( $self,   $c )       = @_;
    my ( $author, $release ) = $c->stash->@{qw(author_name release_name)};

    $c->forward( 'get', [ $author, $release ] );
}

# /contributing-to/$name
sub get : Private {
    my ( $self, $c, $author, $release ) = @_;

    my $contributing_re = qr/CONTRIBUTING|HACKING/i;
    my $files
        = $c->model('API::Release')->interesting_files( $author, $release )
        ->get->{files};

    my $file = List::Util::first { $_->{name} =~ /$contributing_re/ } @$files;

    if ( !exists $file->{path} ) {
        my $release_info = $c->model('ReleaseInfo')->get( $author, $release );
        $c->stash( $release_info->get );
        $c->stash( {
            template => 'contributing_not_found.tx',
        } );
        $c->response->status(404);
    }
    else {
        if ( $file->{pod_lines} && @{ $file->{pod_lines} } ) {
            $c->stash(
                author_name  => $author,
                release_name => $release,
            );
            $c->forward( "/view/release", [ $file->{path} ] );
        }
        else {
            $c->forward( "/source/view",
                [ $file->{author}, $file->{release}, $file->{path} ] );
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
