package MetaCPAN::Web::Controller::Module;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use URI::Escape;

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, @module ) = split( /\//, $req->path );
    
    my $out;
    my $cond;
    if(@module == 1) {
        my $module = shift @module;
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
            $out = $data->{hits} ? $data->{hits}->{hits}->[0]->{_source} : $data;
            $cv->send({}) && return unless($out->{author});
            my $pod = $self->model('/pod/' . join('/', @$out{qw(author release path)}));
            my $release = $self->get_release($out->{author}, $out->{release});
            my $author = $self->get_author($out->{author});
            return ($pod & $author & $release);
        } );

    $get->(
        sub {
            my ($pod, $author, $release) = shift->recv;
            $cv->send(
                       { module => $out,
                         author => $author,
                         pod    => $pod->{raw},
                         release => $release->{hits}->{hits}->[0]->{_source} } );
        } );
    return $cv;
}

sub find_module {
    my ($self, $module) = @_;
    $self->model( '/file/_search',
                             { size   => 1,
                               query  => { match_all => {} },
                               filter => {
                                     and => [
                                         { term =>
                                             { 'documentation' => $module }
                                         },
                                         { term => { status => 'latest', } } ]
                               },
                               sort => [ { 'date' => { order => "desc" } } ] }
      );
}

sub get_module {
    my ($self, $module) = @_;
    warn $module;
    $self->model( '/file/' . $module );
}

1;
