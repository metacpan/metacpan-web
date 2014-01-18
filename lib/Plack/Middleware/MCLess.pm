package Plack::Middleware::MCLess;

# ABSTRACT: LESS CSS support

# Code based off of Plack::Middleware::File::Less
# and Plack::Middleware::Assets

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.02';

use parent qw(Plack::Middleware);
use Digest::MD5 qw(md5_hex);
use Plack::Util;
use Plack::Util::Accessor qw(root files key expires cache cache_ttl);
use Capture::Tiny ':all';
use HTTP::Date  ();

use CSS::Minifier::XS qw(minify);

use Carp;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    my $less = `lessc -v`;
    croak("Can't find lessc command") unless $less;

    if( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {
        # No caching, always build fresh

        # Could have an extra ENV, say 'CSS_DEV' or something
        # so default cache to 10 mins but 0 if CSS_DEV but that
        # seems like more work for someone to help patch so for now
        # take the processing hit - see once this is merged if
        # this is a problem, even a few seconds would help
        $self->cache_ttl('0');
        $self->expires('0');
    } else {
        $self->cache_ttl('30 minutes') unless $self->cache_ttl;
    }

    $self->_build_content;

    return $self;
}


sub call {
    my $self = shift;
    my $env  = shift;

    $env->{'psgix.assets_less'} ||= [];
    my $url = '/_asset_less/' . $self->key . '.css';
    push( @{ $env->{'psgix.assets_less'} }, $url );
    return $self->serve if $env->{PATH_INFO} eq $url;
    return $self->app->($env);
}

sub serve {
    my $self = shift;

    return [
        200,
        [   'Content-Type'   => 'text/css',
            'Content-Length' => length( $self->_get_content ),
            'Expires' =>
                HTTP::Date::time2str( time + ( $self->expires || 2592000 ) ),
        ],
        [ $self->_get_content ]
    ];
}

sub _build_content {
    my $self = shift;

    # We can't use the mtime of the files to work out if we need
    # to rebuild because a file can include other files!

    my $content = join( "\n",
        map { $self->_run_less($_) } @{ $self->files }
    );

    $self->key( md5_hex($content) );
    $self->cache->set( $self->key, $content, $self->cache_ttl );

    return $content;
}

sub _get_content {
    my $self = shift;

    my $content = $self->cache->get($self->key);
    return $content if $content;
    return $self->_build_content;
}

sub _run_less {
    my ($self, $file) = @_;

    my ($stdout, $stderr, $exit) = capture {
        system( 'lessc', $file );
    };
    die $stderr if $stderr;
    return minify($stdout);
}


1;
