package MetaCPAN::Web::Controller::Raw;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub module : Chained('/module/root') PathPart('raw') Args(0) {
    my ( $self, $c ) = @_;
    my $module = $c->stash->{module_name};

    $c->forward( 'view', [$module] );
}

sub release : Chained('/release/root') PathPart('raw') Args {
    my ( $self, $c, @path ) = @_;
    my ( $author, $release ) = $c->stash->@{qw(author_name release_name)};

    $c->forward( 'view', [ $author, $release, @path ] );
}

sub dist : Chained('/dist/root') PathPart('raw') Args {
    my ( $self, $c, @path ) = @_;
    my $dist    = $c->stash->{distribution_name};
    my $release = $c->model('API::Release')->find($dist)->get->{release}
        or $c->detach('/not_found');
    $c->forward( 'view', [ $release->{author}, $release->{name}, @path ] );
}

sub view : Private {
    my ( $self, $c, @module ) = @_;

    my ( $source, $module );
    if ( @module == 1 ) {
        $module = $c->model('API::Module')->find(@module)->get;
        @module = @{$module}{qw(author release path)};
        if ( 3 == grep defined, @module ) {
            $source = $c->model('API::Module')->source(@module)->get;
        }
    }
    else {
        ( $source, $module ) = map { $_->get } (
            $c->model('API::Module')->source(@module),
            $c->model('API::Module')->get(@module),
        );
    }

    $c->detach('/not_found') unless ( $source->{raw} );
    if ( $c->req->parameters->{download} ) {
        my $content_disposition = 'attachment';
        if ( my $filename = $module->{name} ) {
            $content_disposition .= "; filename=$filename";
        }
        $c->res->body( $source->{raw} );
        $c->res->content_type('text/plain');
        $c->res->header( 'Content-Disposition' => $content_disposition );
    }
    else {
        $c->stash( {
            source   => $source->{raw},
            module   => $module,
            template => 'raw.tx'
        } );
    }
}

__PACKAGE__->meta->make_immutable;

1;
