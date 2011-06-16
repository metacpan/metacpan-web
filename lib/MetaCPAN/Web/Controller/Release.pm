package MetaCPAN::Web::Controller::Release;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';
use Scalar::Util qw(blessed);
use List::Util ();

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, $author, $release ) = split( /\//, $req->path );
    my ( $out, $cond );
    if ( $author && $release ) {
        $cond = $self->model('Release')->get( $author, $release );
    }
    else {
        $cond = $self->model('Release')->find($author);
    }

    $cond = $cond->(
        sub {
            my ($data) = shift->recv;
            $out = $data->{hits}->{hits}->[0]->{_source};
            return $self->not_found($req) unless ($out);
            ( $author, $release ) = ( $out->{author}, $out->{name} );
            my $model    = $self->model('Release');
            my $modules  = $model->modules( $author, $release );
            my $root     = $model->root_files( $author, $release );
            my $versions = $model->versions( $out->{distribution} );
            my $author   = $self->model('Author')->get($author);
            return ( $modules & $versions & $author & $root );
        }
    );

    $cond->(
        sub {
            my ( $modules, $versions, $author, $root ) = shift->recv;
            if ( blessed $modules && $modules->isa('Plack::Response') ) {
                $cv->send($modules);
                return;
            }
            $cv->send(
                {
                    release => $out,
                    author  => $author,
                    total   => $modules->{hits}->{total},
                    took    => List::Util::max(
                        $modules->{took}, $root->{took}, $versions->{took}
                    ),
                    root => [
                        sort { $a->{name} cmp $b->{name} }
                        map  { $_->{fields} } @{ $root->{hits}->{hits} }
                    ],
                    versions =>
                      [ map { $_->{fields} } @{ $versions->{hits}->{hits} } ],
                    files => [
                        map {
                            {
                                %{ $_->{fields} },
                                  module   => $_->{fields}->{'_source.module'},
                                  abstract => $_->{fields}->{'_source.abstract'}
                            }
                          } @{ $modules->{hits}->{hits} }
                    ]
                }
            );
        }
    );

    return $cv;
}

1;
