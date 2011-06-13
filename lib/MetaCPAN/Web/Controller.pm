package MetaCPAN::Web::Controller;
use strict;
use warnings;

use base 'Plack::Component';
use MetaCPAN::Web::Request;
use MetaCPAN::Web::View;
use MetaCPAN::Web::Model;
use Encode;
use Scalar::Util qw(blessed);
use Module::Find qw(findallmod);
use Plack::App::URLMap;

__PACKAGE__->mk_accessors(qw(view models controllers));

sub model {
    my ( $self, $model ) = @_;
    return $self->models->{
        $model
        ? "MetaCPAN::Web::Model::$model"
        : "MetaCPAN::Web::Model"
      };
}

sub controller {
    my ( $self, $controller ) = @_;
    unless ( $self->controllers ) {
        $self->controllers(
            {
                map {
                    eval "require $_" or die $@;
                    $_ =>
                      $_->new( view => $self->view, models => $self->models )
                  } grep { $_ ne 'MetaCPAN::Web::Controller' }
                  findallmod 'MetaCPAN::Web::Controller'
            }
        );
    }
    return $self unless ($controller);
    return $self->controllers->{ "MetaCPAN::Web::Controller::$controller" };
}

sub dispatch {
    my $self = shift;
    my $app  = Plack::App::URLMap->new;
    $self->controller;    # build controllers
    foreach my $c ( values %{ $self->controllers } ) {
        $app->map( $c->endpoint => $c );
    }
    return $app;
}

sub endpoint {
    my $self = shift;
    ( my $name = ref $self || $self ) =~ s/^MetaCPAN::Web::Controller//;
    $name =~ s/::/\//g;
    return lc($name);
}

sub template {
    my $tmpl = MetaCPAN::Web::Controller::endpoint(shift) . '.html';
    $tmpl =~ s/^\///;
    return $tmpl;
}

sub content_type {
    'text/html; charset=utf-8';
}

sub raw { 0 }

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    $cv->send( {} );
    return $cv;
}

sub call {
    my ( $self, $env ) = @_;
    my $req = MetaCPAN::Web::Request->new($env);
    my $cv  = $self->index($req);
    return sub {
        my $res = shift;
        $cv->cb(
            sub {
                my $data = shift->recv;
                if ( blessed $data && $data->isa('Plack::Response') ) {
                    $res->( $data->finalize );
                    return;
                }
                my $out = '';
                my $method = $self->raw ? 'process_simple' : 'process';
                $self->view->$method( $self->template, { req => $req, %$data },
                    \$out );
                if ( $self->view->error ) {
                    my $out =
                        ( $ENV{PLACK_ENV} || '' ) eq 'development'
                      ? [ $self->_wrap_template_error( $self->view->error ) ]
                      : [];
                    $res->( [ 500, [ 'Content-Type', 'text/html' ], $out ] );
                }
                else {
                    $out = Encode::encode_utf8($out);
                    $res->(
                        [
                            200, [ 'Content-Type', $self->content_type ], [$out]
                        ]
                    );
                }
            }
        );
    };
}

sub not_found {
    my ( $self, $req ) = @_;
    my $out = '';
    $self->view->process( 'not_found.html', { req => $req }, \$out )
      || warn $self->view->error;
    $out = Encode::encode_utf8($out);
    return Plack::Response->new( 404, [ 'Content-Type', $self->content_type ],
        [$out] );
}

sub _wrap_template_error {
    my ( $self, $error ) = @_;

    return <<"EOF";
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html>
<head>
  <title>template error</title>
</head>
<body>
<pre>$error</pre>
</body>
</html>
EOF
}

1;
