package MetaCPAN::Web::Controller;
use strict;
use warnings;

use base 'Plack::Component';
use MetaCPAN::Web::Request;
use MetaCPAN::Web::View;
use MetaCPAN::Web::Model;
use Encode;
use Scalar::Util qw(blessed);

__PACKAGE__->mk_accessors(qw(view model));

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
    'text/html; charset=utf-8'
}

sub raw { 0 }

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    $cv->send({});
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
                if(blessed $data && $data->isa('Plack::Response')) {
                    $res->( $data->finalize );
                    return;
                }
                my $out  = '';
                my $method = $self->raw ? 'process_simple' : 'process';
                $self->view->$method( $self->template,
                                      { req => $req, %$data }, \$out )
                  || warn $self->view->error;
                $out = Encode::encode_utf8($out);
                $res->(
                        [ 200, [ 'Content-Type', $self->content_type ],
                          [$out] ] );
            } );
    };
}

sub get_author {
    my ( $self, $author ) = @_;
    $self->model->get("/author/$author");

}

sub get_release {
    my ($self, $author, $release) = @_;
    $self->model->get( '/release/_search',
                             {  query  => { match_all => {} },
                                filter => {
                                     and => [
                                         { term => { 'name' => $release } },
                                         { term => { author     => $author } } ]
                                } }
      );
}

sub not_found {
    my ($self, $req) = @_;
    my $out  = '';
    $self->view->process( 'not_found.html',
                          { req => $req }, \$out )
      || warn $self->view->error;
    $out = Encode::encode_utf8($out);
    return Plack::Response->new( 404, [ 'Content-Type', $self->content_type ],
              [$out] );
}

1;
