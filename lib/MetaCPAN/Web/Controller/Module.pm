package MetaCPAN::Web::Controller::Module;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use URI::Escape;

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, @module ) = split( /\//, $req->uri->path );
    
    my $out;
    my $cond;
    if(@module == 1) {
        my $module = uri_unescape(shift @module);
        $cond = $self->find_module($module);
    } elsif(@module > 2) {
        $cond = $self->get_module(join('/', @module));
    } else {
        $cv->send({});
        return;
    }
    
    my $get = $cond->(
        sub {
            my $cv = shift;
            my ($data) = $cv->recv;
            $out = $data->{hits} ? $data->{hits}->{hits}->[0]->{fields} : $data;
            my $pod = $self->model('/pod/' . join('/', @$out{qw(author release path)}));
            my $author = $self->get_author($out->{author});
            return ($pod & $author);
        } );

    $get->(
        sub {
            my ($pod, $author) = shift->recv;
            $cv->send(
                       { module => $out,
                         author => $author,
                         pod    => $pod->{raw}, } );
        } );
    return $cv;
}

sub find_module {
    my ($self, $module) = @_;
    $self->model( '/file/_search',
                             { size   => 100,
                               query  => { match_all => {} },
                               filter => {
                                     and => [
                                         { term =>
                                             { 'documentation.raw' => $module }
                                         },
                                         { term => { status => 'latest', } } ]
                               },
                               fields => [qw(author release path documentation)],
                               sort => [ { 'date' => { order => "desc" } } ] }
      );
}

sub get_module {
    my ($self, $module) = @_;
    $self->model( '/file/' . $module );
}

1;
