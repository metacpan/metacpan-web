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
use Plack::Util::Accessor qw(root files key mtime expires _data cache cache_ttl);
use Capture::Tiny ':all';
use HTTP::Date  ();
use Try::Tiny;
use CSS::Minifier::XS qw(minify);

use Carp;

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new(@_);

    my $less = `lessc -v`;
    croak("Can't find lessc command") unless $less;

    $self->cache_ttl('10 minutes') unless $self->cache_ttl;

    $self->_build_content;

    return $self;
}


sub call {
    my $self = shift;
    my $env  = shift;

    if ( $ENV{PLACK_ENV} && $ENV{PLACK_ENV} eq 'development' ) {
        # Try and reload if needed
        my @mtime = map { ( stat($_) )[9] } @{ $self->files };
        $self->_build_content
            if ( $self->mtime < ( reverse( sort(@mtime) ) )[0] );
    }

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
            # 'Expires' =>
            #     HTTP::Date::time2str( time + ( $self->expires || 2592000 ) ),
        ],
        [ $self->_get_content ]
    ];
}

sub _build_content {
    my $self = shift;

    my $content = join( "\n",
            map { $self->_run_less($_) } @{ $self->files }
    );

    $self->_set_content($content);

    return $content;
}

sub _set_content {
    my $self = shift;
    my $content = shift || croak "No content";

    $self->key( md5_hex($content) );

    if(my $cache = $self->cache) {
        $cache->set( $self->key, $content, $self->cache_ttl );
    } else {
        $self->_data($content);
    }
}

sub _get_content {
    my $self = shift;

    if(my $cache = $self->cache) {
        my $content = $cache->get($self->key);
        return $content if $content;
        return $self->_build_content;
    } else {
        return $self->_data();
    }
}


sub _run_less {
    my ($self, $file) = @_;

    my ($stdout, $stderr, $exit) = capture {
        system( 'lessc', $file );
    };
    croak $stderr if $stderr;
    return minify($stdout);
}


1;
