package MetaCPAN::Web::Controller::Raw;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller::Module';
use Plack::Response;
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
                if ( $req->params->{download} ) {
                    my $content_disposition = 'attachment';
                    if (my $filename = $module->{name}) {
                        $content_disposition .= "; filename=$filename";
                    }
                    my $response = Plack::Response->new(
                        200,
                        [   'Content-Disposition' => $content_disposition,
                            'Content-Type'        => 'text/plain',
                        ],
                        [ $source->{raw} ],
                    );

                    $cv->send($response);
                }
                else {
                    $cv->send(
                        { source => $source->{raw}, module => $module } );
                }
            }
            else {
                $cv->send( $self->not_found($req) );
            }
        }
    );
    return $cv;
}

1;
