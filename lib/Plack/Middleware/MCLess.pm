package Plack::Middleware::MCLess;

# ABSTRACT: LESS CSS support

# Code based off of  Plack::Middleware::File::Less;;

use strict;
use warnings;
use 5.008_001;
our $VERSION = '0.02';

use parent qw(Plack::Middleware);
use Plack::Util;
use Plack::Util::Accessor qw(root);
use Capture::Tiny ':all';
use Try::Tiny;

use IPC::Open3 qw(open3);
use Carp;

sub prepare_app {
    my $self = shift;

    my $less = `lessc -v`;
    unless($less) {
        Carp::croak("Can't find lessc command");
    }
}

sub _run_less {
    my ($self, $file) = @_;

    my ($stdout, $stderr, $exit) = capture {
        system( 'lessc', $file );
    };

    croak $stderr if $stderr;
    return $stdout;
}

sub less_response {
    my ($self, $path_info) = @_;

    my $docroot = $self->root || ".";
    my $path = $docroot . $path_info;

    return [404, [], []] unless -f $path;

    try {
        my $css = $self->_run_less($path);
        return [
            200,
            [
                'Content-Type' => 'text/css',
                'Content-Length' => length $css,
            ],
            ["$css"]
        ];
    } catch {
        return [
            500,
            [
                'Content-Type' => 'text/css',
                'Content-Length' => length $_,
            ],
            ["$_"]
        ];

    };

}


sub call {
    my ($self, $env) = @_;

    my $path_info = $env->{PATH_INFO};

    if( $path_info =~ /\.less$/ ) {

        return $self->less_response($path_info);

    } else {
        # carry on
        return $self->app->($env);
    }


    # if ($env->{PATH_INFO} =~ s/\.css$/.less/i) {
    #     my $res = $self->app->($env);

    #     return $res unless ref $res eq 'ARRAY';

    #     if ($res->[0] == 200) {
    #         my $less;
    #         Plack::Util::foreach($res->[2], sub { $less .= $_[0] });


    #         my $h = Plack::Util::headers($res->[1]);
    #         $h->set('Content-Type'   => 'text/css');
    #         $h->set('Content-Length' => length $css);

    #         $res->[2] = [$css];
    #     }
    #     elsif ($res->[0] == 404) {
    #         $env->{PATH_INFO} = $orig_path_info;
    #         $res = $self->app->($env);
    #     }

    #     return $res;
    # }
    # return $self->app->($env);
}

1;