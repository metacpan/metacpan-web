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
    my $module = join('/', @module);
    my $cond = $self->get_source($module) & $self->get_module($module);
    $cond->(sub {
        my ($source, $module) = shift->recv;
        $cv->send({
            source => $source->{raw}, module => $module
        });
    });
    return $cv;
}


sub get_source {
    my ($self, $module) = @_;
    $self->model( '/source/' . $module );
}

1;
