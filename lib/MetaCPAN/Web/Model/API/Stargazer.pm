package MetaCPAN::Web::Model::API::Stargazer;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

use List::MoreUtils qw(uniq);

sub find_starred {
    my ( $self, $user, $name ) = @_;

    my $starred      = $self->by_user( $user->{user} );
    my $starred_data = $starred->recv;
    my @starred_modules
        = map { $_->{fields}->{module} } @{ $starred_data->{hits}->{hits} };
    my $total_starred = @starred_modules;

    foreach my $module (@starred_modules) {
        if ( $name eq $module ) {
            return (
                {
                    mystargazer   => 1,
                    total_starred => $total_starred,
                }
            );
        }

    }
    return (
        {
            mystargazer   => 0,
            total_starred => $total_starred,
        }
    );

}

sub by_user {
    my ( $self, $user ) = @_;
    return $self->request(
        '/stargazer/_search',
        {
            query  => { match_all => {} },
            filter => { term      => { user => $user }, },
            fields => [qw(date module author)],
            size   => 250,
        }
    );
}
__PACKAGE__->meta->make_immutable;
