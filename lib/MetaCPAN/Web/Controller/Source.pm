package MetaCPAN::Web::Controller::Source;

use Moose;
use namespace::autoclean;
use experimental 'postderef';

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub module : Chained('/module/root') PathPart('source') Args(0) {
    my ( $self, $c ) = @_;
    my $module = $c->stash->{module_name};

    $c->forward( 'view', [$module] );
}

sub release : Chained('/release/root') PathPart('source') Args {
    my ( $self, $c, @path ) = @_;
    my ( $author, $release ) = $c->stash->@{qw(author_name release_name)};

    $c->forward( 'view', [ $author, $release, @path ] );
}

sub dist : Chained('/dist/root') PathPart('source') Args {
    my ( $self, $c, @path ) = @_;
    my $dist    = $c->stash->{distribution_name};
    my $release = $c->model('API::Release')->find($dist)->get->{release}
        or $c->detach('/not_found');
    $c->forward( 'view', [ $release->{author}, $release->{name}, @path ] );
}

sub view : Private {
    my ( $self, $c, @path ) = @_;

    if ( $c->req->params->{raw} ) {
        $c->detach( 'raw', \@path );
    }

    my ( $source, $file );
    if ( @path == 1 ) {
        $file = $c->model('API::Module')->find(@path)->get;
        @path = @{$file}{qw(author release path)};
        if ( 3 == grep defined, @path ) {
            $source = $c->model('API::File')->source(@path)->get;
        }
    }
    else {
        ( $source, $file ) = map { $_->get } (
            $c->model('API::File')->source(@path),
            $c->model('API::File')->get(@path),
        );
    }

    $c->detach('/not_found')
        if grep +( $_->{code} || 0 ) > 399, $source, $file;

    if ( $file->{directory} ) {
        my $files = $c->model('API::File')->dir(@path)->get;

        $self->add_cache_headers( $c, $file );

        $c->stash( {
            files     => $files,
            author    => shift @path,
            release   => shift @path,
            directory => \@path,
            maturity  => $file->{maturity},
            template  => 'browse.tx',
        } );
    }
    elsif ( exists $source->{raw} ) {

        # hack to work around Xslate. utf8-flagged content will be encoded to
        # output, which is ok. non-utf8 content may be decoded before
        # re-encoding, which can break.
        utf8::upgrade( $source->{raw} );

        $file->{content} = $source->{raw};
        $c->stash( {
            file     => $file,
            maturity => $file->{maturity},
        } );
        $c->forward('content');
    }
    else {
        $c->detach('/not_found');
    }
}

sub raw : Private {
    my ( $self, $c, @path ) = @_;

    if ( @path == 1 ) {
        my $module = $c->model('API::Module')->find(@path)->get;
        @path = @{$module}{qw(author release path)};
    }

    $c->res->redirect(
        $c->view->api_public . '/source/' . join( '/', @path ) );
    $c->detach;
}

sub add_cache_headers {
    my ( $self, $c, $file ) = @_;

    $c->add_surrogate_key('SOURCE');
    $c->add_dist_key( $file->{distribution} );
    $c->add_author_key( $file->{author} );

    $c->browser_max_age('1h');
    $c->cdn_max_age('1y');

    $c->res->last_modified( $file->{date} );
}

my %syntax_types = (
    'text/x-script.perl'        => 'perl',
    'text/x-script.perl-module' => 'perl',

    # No separate pod brush as of 2011-08-04.
    'text/x-pod'             => 'perl',
    'text/yaml'              => 'yaml',
    'application/json'       => 'javascript',
    'application/javascript' => 'javascript',
    'text/x-c'               => 'c',
    'text/markdown'          => 'markdown',

    # Are other changelog files likely to be in CPAN::Changes format?
    'text/x-cpan-changelog' => 'cpanchanges',
);

sub content : Private {
    my ( $self, $c ) = @_;

    my $file = $c->stash->{file};

    $self->add_cache_headers( $c, $file );

    # could this be a method/function somewhere else?
    if ( !$file->{binary} ) {
        $c->stash( {
            source      => $file->{content},
            syntax_type => $self->detect_filetype($file),
        } );
    }
    $c->res->last_modified( $file->{date} );
    $c->stash( {
        file     => $file,
        template => 'source.tx',
    } );
}

# Class method to ease testing.
sub detect_filetype {
    my ( $self, $file ) = @_;

    my $mime = $file->{mime} || 'text/plain';
    $syntax_types{$mime}     || 'plain';
}

__PACKAGE__->meta->make_immutable;

1;
