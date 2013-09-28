package MetaCPAN::Web::Controller::Source;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('source') : Chained('/') : Args {
    my ( $self, $c, @module ) = @_;

    my ( $source, $module );
    if ( @module == 1 ) {
        $module = $c->model('API::Module')->find(@module)->recv;
        $module[0] = join '/', $module->{author}, $module->{release},
            $module->{path};
        $source = $c->model('API::Module')->source(@module)->recv;
    }
    else {
        ( $source, $module ) = (
            $c->model('API::Module')->source(@module)->recv,
            $c->model('API::Module')->get(@module)->recv,
        );
    }


    if ( $module->{directory} ) {
        my $files = $c->model('API::File')->dir(@module)->recv;
        $c->res->last_modified($module->{date});
        $c->stash(
            {   template => 'browse.html',
                files => [ map { $_->{fields} } @{ $files->{hits}->{hits} } ],
                total => $files->{hits}->{total},
                took  => $files->{took},
                author => shift @module,
                release => shift @module,
                directory => \@module,
            }
        );
    }
    elsif ( exists $source->{raw} ) {
        $module->{content} = $source->{raw};
        $c->stash({
            file => $module,
        });
        $c->forward('content');
    }
    else {
        $c->detach('/not_found');
    }
}

sub content : Private {
    my ($self, $c) = @_;

    # FIXME: $module should really just be $file
    my $module = $c->stash->{file};

        # could this be a method/function somewhere else?
        if ( !$module->{binary} ) {
            my $filetype = $self->detect_filetype($module);
            $c->stash( { source => $module->{content}, filetype => $filetype } );
        }
        $c->res->last_modified($module->{date});
        $c->stash(
            {   template => 'source.html',
                module   => $module,
            }
        );
}

# Class method to ease testing.
sub detect_filetype {
    my ($self, $file) = @_;

    if( defined($file->{path}) ){
        local $_ = $file->{path};

        # No separate pod brush as of 2011-08-04.
        return 'pl'   if /\. ( p[ml] | psgi | pod ) $/ix;

        return 'pl'   if /^ cpanfile $/ix;

        return 'yaml' if /\. ya?ml $/ix;

        return 'js'   if /\. js(on)? $/ix;

        return 'c'    if /\. ( c | h | xs ) $/ix;

        # Are other changelog files likely to be in CPAN::Changes format?
        return 'cpanchanges' if /^ Changes $/ix;

        return 'pl'   if $file->{mime} =~ /perl/;
    }

    # Default to plain text.
    return 'plain';
}

1;
