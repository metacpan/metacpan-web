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

sub _routes {
}

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
