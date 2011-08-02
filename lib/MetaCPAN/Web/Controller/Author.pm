package MetaCPAN::Web::Controller::Author;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

sub index : Path : Args(1) {
    my ( $self, $c, $id ) = @_;
    
    # force consistent casing in URLs
    if ( $id ne uc( $id ) ) {
        $c->res->redirect( '/author/' . uc( $id ), 301 );
        $c->detach;
    }
    
    my $author_cv = $c->model('API::Author')->get($id);
    # this should probably be refactored into the model?? why is it here
    my $releases_cv = $c->model('API::Release')->request(
        '/release/_search',
        {   query => {
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
            sort => [
                'distribution', { 'version_numified' => { reverse => \1 } }
            ],
            fields => [qw(author distribution name status abstract date)],
            size   => 1000,
        }
    );

    my ( $author, $releases ) = ( $author_cv & $releases_cv )->recv;
    $c->detach('/not_found') unless ( $author->{pauseid} );

    $c->stash(
        {   author => $author,
            releases =>
                [ map { $_->{fields} } @{ $releases->{hits}->{hits} } ],
            took     => $releases->{took},
            total    => $releases->{hits}->{total},
            template => 'author.html'
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
