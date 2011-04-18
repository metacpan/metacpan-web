package MetaCPAN::Web::Controller::Author;
use strict;
use warnings;
use base 'MetaCPAN::Web::Controller';

sub index {
    my ( $self, $req ) = @_;
    my $cv = AE::cv;
    my ( undef, undef, $id ) = split( /\//, $req->uri->path );

    my $out;

    my $author = $self->model( '/author/'. $id);
    my $releases = $self->model( '/release/_search', {
        query => { match_all => { } },
        filter => { term => { author => $id } },
        sort => ['distribution', {
            'version_numified' => {
                reverse => \1
            }
        }],
        size => 100,
    });
    
    ($author & $releases)->(sub {
        my ($author, $releases) = shift->recv;
        $cv->send({
            author => $author,
            releases => [map { $_->{_source} } @{$releases->{hits}->{hits}}],
        });
    });

    return $cv;
}

1;
