package MetaCPAN::Web::Controller::Author;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, $id ) = split( /\//, $req->path );

    my $out;

    my $author   = $self->model('Author')->get($id);
    my $releases = $self->model->request(
        '/release/_search',
        {
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        and => [
                            { term => { author => uc($id) } },
                            { term => { status => 'latest' } }
                        ]
                    },
                }
            },
            sort =>
              [ 'distribution', { 'version_numified' => { reverse => \1 } } ],
            fields => [qw(author distribution name status abstract date)],
            size   => 1000,
        }
    );

    ( $author & $releases )->(
        sub {
            my ( $author, $releases ) = shift->recv;
            unless ( $author->{pauseid} ) {
                $cv->send( $self->not_found($req) );
                return;
            }
            $cv->send(
                {
                    author => $author,
                    releases =>
                      [ map { $_->{fields} } @{ $releases->{hits}->{hits} } ],
                    took  => $releases->{took},
                    total => $releases->{hits}->{total}
                }
            );
        }
    );

    return $cv;
}

1;
