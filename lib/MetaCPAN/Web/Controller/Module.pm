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
    
    my $data;
    my $cond;
    if(@module == 1) {
        $cond = $self->model('Module')->find($module[0]);
    } elsif(@module > 2) {
        $cond = $self->model('Module')->get(@module);
    } else {
        $cv->send({});
        return;
    }
    
    my $get = $cond->(
        sub {
            $data = shift->recv;
            return $self->not_found($req) unless($data->{name});
            my $pod = $self->model->request('/pod/' . join('/', @module));
            my $release = $self->model('Release')->get($data->{author}, $data->{release});
            my $author = $self->model('Author')->get($data->{author});
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
                       { module => $data,
                         author => $author,
                         pod    => $pod->{raw},
                         release => $release->{hits}->{hits}->[0]->{_source} } );
        } );
    return $cv;
}

1;
