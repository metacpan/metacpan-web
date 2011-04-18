package MetaCPAN::Web::Controller;
use strict;
use warnings;

use base 'Plack::Component';
use Plack::Request;
use MetaCPAN::Web::View;
use MetaCPAN::Web::Model;
use Encode;

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
    my $req = Plack::Request->new($env);
    my $cv  = $self->index($req);
    return sub {
        my $res = shift;
        $cv->cb(
            sub {
                my $data = shift->recv;
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

1;
