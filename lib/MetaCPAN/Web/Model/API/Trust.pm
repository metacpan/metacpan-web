package MetaCPAN::Web::Model::API::Trust;
use Moose;
use MooseX::MarkAsMethods autoclean => 1;

extends 'MetaCPAN::Web::Model::API';

use List::MoreUtils qw(uniq);

sub find_trust {
    my ( $self, $user, $name ) = @_;

    my $trusted      = $self->by_user( $user->{user} );
    my $trusted_data = $trusted->recv;
    my @trusted_authors
        = map { $_->{fields}->{author} } @{ $trusted_data->{hits}->{hits} };
    my $total_trusted = @trusted_authors;

    foreach my $author (@trusted_authors) {
        if ( $name eq $author ) {
            return (
                {
                    active_trust  => 1,
                    total_trusted => $total_trusted,
                }
            );
        }

    }
    return (
        {
            total_trusted => $total_trusted,
        }
    );

}

sub by_user {
    my ( $self, $user ) = @_;
    return $self->request(
        '/trust/_search',
        {
            query  => { match_all => {} },
            filter => { term      => { user => $user }, },
            fields => [qw(date author)],
            size   => 250,
        }
    );
}
__PACKAGE__->meta->make_immutable;
