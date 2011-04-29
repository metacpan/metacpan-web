package MetaCPAN::Web::Controller;
use strict;
use warnings;

use base 'Plack::Component';
use MetaCPAN::Web::Request;
use MetaCPAN::Web::View;
use MetaCPAN::Web::Model;
use Encode;
use Scalar::Util qw(blessed);

__PACKAGE__->mk_accessors(qw(view));

sub model {
    my $self = shift;
    return MetaCPAN::Web::Model::metacpan(@_);
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
                $self->view->process( $self->template,
                                      { req => $req, %$data }, \$out )
                  || warn $self->view->error;
                $out = Encode::encode_utf8($out);
                $res->(
                        [ 200, [ 'Content-Type', 'text/html; charset=utf-8' ],
                          [$out] ] );
            } );
    };
}

sub get_author {
    my ( $self, $author ) = @_;
    $self->model("/author/$author");

}

sub get_release {
    my ($self, $author, $release) = @_;
    $self->model( '/release/_search',
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
    return Plack::Response->new( 404, [ 'Content-Type', 'text/html; charset=utf-8' ],
              [$out] );
}

1;
