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
    my $cond = $self->model('Module')->source(@module)
        & $self->model('Module')->get(@module);
    $cond->(
        sub {
            my ( $source, $module ) = shift->recv;
            if ( $source->{raw} ) {
                $cv->send( { source => $source->{raw}, module => $module } );
            }
            else {
                $cv->send( $self->not_found($req) );
            }
        }
    );
    return $cv;
}

1;
