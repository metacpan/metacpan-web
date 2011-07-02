package MetaCPAN::Web::Controller::Author;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index :Path :Args(1) {
    my ( $self, $c, $id ) = @_;
    my $cv = AE::cv;

    my $out;

    my $author   = $c->model('API::Author')->get($id);
    # this should probably be refactored into the model?? why is it here
    my $releases = $c->model('API::Release')->request(
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
                $cv->send( $self->not_found($c->req) );
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
    
    $c->stash({%{$cv->recv}, template => 'author.html'});
}

__PACKAGE__->meta->make_immutable;

1;
