package MetaCPAN::Middleware::OldUrls;
use strict;
use warnings;

use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(router);

use Plack::Request;
use Router::Simple;
use Ref::Util qw(is_hashref is_coderef);
use URI;

sub _formatter {
    my $format = shift;
    my @placeholders;
    $format =~ s{%}{%%}g;
    if (
        $format =~ s{:(\w+)}{
            push @placeholders, $1;
            '%s'
        }ge
        )
    {
        return sub {
            my ($arg)  = @_;
            my @values = map $arg->{$_}, @placeholders;
            sprintf $format, @values;
        }
    }
    else {
        return undef;
    }
}

my $feed_type = sub {
    my ( $env, $match ) = @_;
    my $type
        = lc( Plack::Request->new($env)->query_parameters->{type} || 'rdf' );
    $match->{type}
        = $type eq 'rss' || $type eq 'rdf' ? 'rss'
        : $type eq 'atom'                  ? 'atom'
        :                                    return 0;
    return 1;
};

my $activity_type = sub {
    my $type = shift;
    sub {
        my ( $env, $match ) = @_;
        my $q = Plack::Request->new($env)->query_parameters;
        if ( !$type ) {
        }
        elsif ( $q->{$type} ) {
            $match->{$type} = $q->{$type};
        }
        else {
            return 0;
        }
        if ( $q->{res} ) {
            $match->{query}{res} = $q->{res};
        }
        return 1;
    };
};

#<<<
sub _routes { (
    [ '/permission/author/:author',         '/author/:author/permissions' ],
    [ '/permission/distribution/:dist',     '/dist/:dist/permissions' ],
    [ '/permission/module/:module',         '/module/:module/permissions' ],

    [ '/feed/recent',             '/recent.:type',                  $feed_type ],
    [ '/feed/news',               '/news.:type',                    $feed_type ],
    [ '/feed/author/:author',     '/author/:author/activity.:type', $feed_type ],
    [ '/feed/distribution/:dist', '/dist/:dist/releases.:type',     $feed_type ],

    [ '/activity', '/author/:author/activity.svg',      $activity_type->('author') ],
    [ '/activity', '/dist/:distribution/activity.svg',  $activity_type->('distribution') ],
    [ '/activity', '/module/:module/activity.svg',      $activity_type->('module') ],
    [ '/activity', '/activity/distributions.svg',       $activity_type->('new_dists') ],
    [ '/activity', '/activity/releases.svg',            $activity_type->() ],

    [ '/changes/distribution/:dist',        '/dist/:dist/changes' ],
    [ '/changes/release/:author/:release',  '/release/:author/:release/changes' ],

    [ '/contributing-to/:dist',             '/dist/:dist/contribute' ],
    [ '/contributing-to/:author/:release',  '/release/:author/:release/contribute' ],

    [ '/river/gauge/:dist', '/dist/:dist/river.svg' ],

    [ '/requires/distribution/:dist',   '/dist/:dist/requires' ],
    [ '/requires/module/:module',       '/module/:module/requires' ],

    [ '/release/:dist',                 '/dist/:dist' ],
    [ '/release/:dist/plussers',        '/dist/:dist/plussers' ],

    [ '/release/:dist/source/:*file',   '/dist/:dist/source/:file' ],
    [ '/source/:module',                '/module/:module/source' ],
    [ '/source/:author/:release/:*file', '/release/:author/:release/source/:file' ],

    [ '/raw/:author/:release/:*file',   '/release/:author/:release/raw/:file' ],

    [ '/diff/release/:before_author/:before_release/:after_author/:after_release',
        '/release/:after_author/:after_release/diff/:before_author/:before_release' ],
    [
        '/diff/file',
        '/release/:after_author/:after_release/diff/:before_author/:before_release/:path',
        sub {
            my ($env, $match) = @_;
            my $q = Plack::Request->new($env)->query_parameters;
            (
                $match->{before_author},
                $match->{before_release},
            ) = split m{/}, $q->{source};
            (
                $match->{after_author},
                $match->{after_release},
                $match->{path},
            ) = split m{/}, $q->{target}, 3;
            $match->{path} //= '';
            return 1;
        },
    ],

    [ '/pod/release/:author/:release/:*file',   '/release/:author/:release/view/:file' ],
    [ '/pod/distribution/:dist/:*file',         '/dist/:dist/view/:file' ],
) }
#>>>

sub prepare_app {
    my $self = shift;

    my $router = Router::Simple->new;
    for my $r ( $self->_routes ) {
        my $pattern = shift @$r;
        my $dest    = shift @$r;

        if ( !is_hashref($dest) ) {
            $dest = { url => $dest, };
        }

        my %splat;
        my $s = 0;
        $pattern =~ s{\*|:\*(\w+)}{
            if (defined $1) {
                $splat{$s} = $1;
            }
            $s++;
            '*';
        }ge;

        my $options;
        $options = pop @$r
            if is_hashref( $r->[-1] );
        $options->{on_match} = pop @$r
            if is_coderef( $r->[-1] );
        $dest->{code} = pop @$r
            if defined $r->[-1] && $r->[-1] =~ /\A[0-9]{3}\z/;

        if (@$r) {
            die "Invalid options for $pattern: " . join( ' ', @$r );
        }

        my $url       = $dest->{url};
        my $formatter = ref $url eq 'CODE' ? $url : _formatter($url);
        if ($formatter) {
            my $on_match = $options->{on_match};
            $options->{on_match} = sub {
                my ( $env, $match ) = @_;
                if ( defined $on_match && !$on_match->(@_) ) {
                    return 0;
                }
                if ( keys %splat ) {
                    for my $i ( 0 .. $#{ $match->{splat} } ) {
                        $match->{ $splat{$i} || "splat$i" }
                            = $match->{splat}[$i];
                    }
                }
                if ( defined $match->{author} ) {
                    $match->{author} = uc $match->{author};
                }
                $match->{url} = $formatter->($match);
                if ( my $q = $match->{query} ) {
                    my $url = URI->new( $match->{url} );
                    $url->query_form( [
                        $url->query_form,
                        ( map +( $_ => $q->{$_} ), sort keys %$q ),
                    ] );
                    $match->{url} = $url->as_string;
                }
                return 1;
            };
        }
        $router->connect( $pattern, $dest, $options );
    }
    $self->router($router);
}

sub call {
    my ( $self, $env ) = @_;

    my $router = $self->router;
    if ( $env->{PATH_INFO} =~ m{\A(.+)/\z}s ) {
        $env = { %$env, PATH_INFO => $1, };
    }
    if ( my $match = $router->match($env) ) {
        my $url  = $match->{url};
        my $code = $match->{code} // 301;
        return [ $code, [ Location => $url ], [] ];
    }

    return $self->app->($env);
}

1;
