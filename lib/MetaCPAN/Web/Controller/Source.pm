package MetaCPAN::Web::Controller::Source;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : PathPart('source') : Chained('/') : Args {
    my ( $self, $c, @module ) = @_;

    my( $source , $module );
    if ( @module == 1 ) {
        $module = $c->model('API::Module')->find(@module)->recv;
        $module[0] = join '/' , $module->{author} , $module->{release} , $module->{path};
        $source = $c->model('API::Module')->source(@module)->recv;
    }
    else {
        ( $source, $module )
            = ( $c->model('API::Module')->source(@module)
                & $c->model('API::Module')->get(@module) )->recv;
    }

    if ( $source->{raw} ) {
        # could this be a method/function somewhere else?
        my $filetype = do {
            local $_ = $module->{path};
            # what other file types can we check for?
            m!\.p[ml]$!i  ? 'pl'   :
            m!\.pod$!     ? 'pl'   :   # no separate pod brush as of 2011-08-04
            m!\.ya?ml$!   ? 'yaml' :
            m!\.js(on)?$! ? 'js'   :
            $module->{mime} =~ /perl/ ? 'pl' :
                # default to plain text
                'plain';
        };
        $c->stash(
            {   template => 'source.html',
                source   => $source->{raw},
                module   => $module,
                filetype => $filetype,
            }
        );
    }
    else {
        $c->detach('/not_found');
    }
}

1;
