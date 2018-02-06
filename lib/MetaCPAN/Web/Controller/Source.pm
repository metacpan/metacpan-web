package MetaCPAN::Web::Controller::Source;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args {
    my ( $self, $c, @module ) = @_;

    $c->add_surrogate_key('SOURCE');
    $c->browser_max_age('1h');

    if ( @module == 1 ) {

        # /source/Foo::bar or /source/AUTHOR/
        $c->cdn_max_age('1h');

    }
    else {
        # SO can cache for a LONG time
        # /source/AUTHOR/anything e.g /source/ETHER/YAML-Tiny-1.67/
        $c->cdn_max_age('1y');
    }

    my ( $source, $module );
    if ( @module == 1 ) {
        $module = $c->model('API::Module')->find(@module)->get;
        $module[0] = join q{/}, $module->{author}, $module->{release},
            $module->{path};
        $source = $c->model('API::Module')->source(@module)->get;
    }
    else {
        ( $source, $module ) = map { $_->get } (
            $c->model('API::Module')->source(@module),
            $c->model('API::Module')->get(@module),
        );
    }
    if ( $module->{directory} ) {
        my $files = $c->model('API::File')->dir(@module)->get;
        $c->res->last_modified( $module->{date} );
        $c->stash( {
            template  => 'browse.html',
            files     => $files,
            author    => shift @module,
            release   => shift @module,
            directory => \@module,
        } );
    }
    elsif ( exists $source->{raw} ) {
        $module->{content} = $source->{raw};
        $c->stash( {
            file => $module,
        } );
        $c->forward('content');
    }
    else {
        $c->detach('/not_found');
    }
}

sub content : Private {
    my ( $self, $c ) = @_;

    # FIXME: $module should really just be $file
    my $module = $c->stash->{file};

    # could this be a method/function somewhere else?
    if ( !$module->{binary} ) {
        my $filetype = $self->detect_filetype($module);
        $c->stash( { source => $module->{content}, filetype => $filetype } );
    }
    $c->res->last_modified( $module->{date} );
    $c->stash( {
        template => 'source.html',
        module   => $module,
    } );
}

# Class method to ease testing.
sub detect_filetype {
    my ( $self, $file ) = @_;

    if ( defined( $file->{path} ) ) {
        local $_ = $file->{path};

        # No separate pod brush as of 2011-08-04.
        return 'perl' if /\. ( p[ml] | psgi | pod ) $/ix;

        return 'perl' if /^ (cpan|alien)file $/ix;

        return 'yaml' if /\. ya?ml $/ix;

        return 'javascript' if /\. js(on)? $/ix;

        return 'c' if /\. ( c | h | xs ) $/ix;

        # Are other changelog files likely to be in CPAN::Changes format?
        return 'cpanchanges' if /^ Changes $/ix;
    }

    # If no paths matched try mime type (which likely comes from the content).
    if ( defined( $file->{mime} ) ) {
        local $_ = $file->{mime};

        return 'perl' if /perl/;
    }

    # Default to plain text.
    return 'plain';
}

__PACKAGE__->meta->make_immutable;

1;
