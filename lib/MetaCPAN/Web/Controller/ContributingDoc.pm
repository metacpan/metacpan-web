package MetaCPAN::Web::Controller::ContributingDoc;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use List::Util ();

sub index : Chained('/') : PathPart('contributing-to') : CaptureArgs(0) { }

sub dist : Chained('index') : PathPart('') : Args(1) {
    my ( $self, $c, $dist ) = @_;

    my $release = $c->model('API::Release')->find($dist)->get->{release};
    if ( $release && $release->{author} && $release->{name} ) {
        return $c->forward( 'get', [ $release->{author}, $release->{name} ] );
    }
    $c->detach('/not_found');
}

sub release : Chained('index') : PathPart('') : Args(2) {
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

    my $contributing_re = qr/(CONTRIBUTING|HACKING)/i;
    my $files
        = $c->model('API::Release')->interesting_files(@args)->get->{files};

    my $file = List::Util::first { $_->{name} =~ /$contributing_re/ } @$files;

    if ( !exists $file->{path} ) {
        my $release = join q{/}, @args;
        $c->stash( {
            message => 'Ask the author on how to contribute to this release.',
            suggest => {
                description => 'Try the release info page',
                url         => $c->uri_for("/release/$release"),
                link_text   => $release,
            }
        } );
        $c->detach('/not_found');
    }
    else {
        my $path = join '/' => @$file{qw(author release path)};
        if ( $path =~ /\.(pod|pm)$/ ) {
            $c->res->redirect( "/pod/release/$path", 301 );
        }
        else {
            $c->res->redirect( "/source/$path", 301 );
        }
    }
}

__PACKAGE__->meta->make_immutable;

1;
