package MetaCPAN::Web::Controller::Source;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller::Module';
use URI::Escape;

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, @module ) = split( /\//, $req->path );
    
    my $out;
    my $cond = $self->model('Module')->source(@module) & $self->model('Module')->get(@module);
    $cond->(sub {
        my ($source, $module) = shift->recv;
        $cv->send({
            source => $source->{raw}, module => $module
        });
    });
    return $cv;
}

1;
