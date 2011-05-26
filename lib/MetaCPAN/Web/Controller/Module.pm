package MetaCPAN::Web::Controller::Module;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use URI::Escape;
use Scalar::Util qw(blessed);

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, @module ) = split( /\//, $req->path );
    
    my $out;
    my $cond;
    if(@module == 1) {
        my $module = shift @module;
        $cond = $self->model('Module')->find($module);
    } elsif(@module > 2) {
        $cond = $self->model('Module')->get(@module);
    } else {
        $cv->send({});
        return;
    }
    
    my $get = $cond->(
        sub {
            my $cv = shift;
            my ($data) = $cv->recv;
            $out = $data->{hits} ? $data->{hits}->{hits}->[0]->{_source} : $data;
            return $self->not_found($req) unless($out);
            my $pod = $self->model->request('/pod/' . join('/', @$out{qw(author release path)}));
            my $release = $self->model('Release')->get($out->{author}, $out->{release});
            my $author = $self->model('Author')->get($out->{author});
            return ($pod & $author & $release);
        } );

    $get->(
        sub {
            my ($pod, $author, $release) = shift->recv;
            if(blessed $pod && $pod->isa('Plack::Response')) {
                $cv->send($pod);
                return;  
            } 
            $cv->send(
                       { module => $out,
                         author => $author,
                         pod    => $pod->{raw},
                         release => $release->{hits}->{hits}->[0]->{_source} } );
        } );
    return $cv;
}

1;
