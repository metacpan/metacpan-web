package MetaCPAN::Web::Model::API::Favorite;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

use Future;

sub by_dist {
    my ( $self, $dist ) = @_;

    return $self->request( '/favorite/agg_by_distributions',
        { distribution => $dist } )->then( sub {
        my $data = shift;
        Future->done( {
            favorites => $data->{favorites}{$dist},
            took      => $data->{took},
        } );
        } );
}

sub by_user {
    my ( $self, $user, $size ) = @_;
    $size ||= 250;
    return Future->done( [] )
        if !defined $user;
    my $ret
        = $self->request( "/favorite/by_user/$user", { size => $size } )
        ->transform(
        done => sub {
            my $data = shift;
            return [] unless exists $data->{favorites};
            return $data->{favorites};
        }
        );
}

sub recent {
    my ( $self, $page, $page_size ) = @_;
    $self->request( '/favorite/recent', undef,
        { size => $page_size, page => $page } )->then( sub {
        my $data     = shift;
        my @user_ids = map { $_->{user} } @{ $data->{favorites} };
        return Future->done($data) unless @user_ids;
        $self->request( '/author/by_user', undef, { user => \@user_ids } )
            ->transform(
            done => sub {
                my $authors = shift;
                if ( $authors and exists $authors->{authors} ) {
                    my %author_for_user_id
                        = map { $_->{user} => $_->{pauseid} }
                        @{ $authors->{authors} };
                    for my $fav ( @{ $data->{favorites} } ) {
                        next
                            unless exists $author_for_user_id{ $fav->{user} };
                        $fav->{clicked_by_author}
                            = $author_for_user_id{ $fav->{user} };
                    }
                }
                return $data;
            }
            );
        } );
}

sub leaderboard {
    my ($self) = @_;
    $self->request('/favorite/leaderboard');
}

sub find_plussers {
    my ( $self, $distribution ) = @_;

    # search for all users, match all according to the distribution.
    $self->request("/favorite/users_by_distribution/$distribution")
        ->then( sub {
        my $plusser_data = shift;
        my @plusser_users
            = $plusser_data->{users} ? @{ $plusser_data->{users} } : ();
        my $took = $plusser_data->{took} || 0;

        return Future->done( {
            plussers => {
                authors      => [],
                others       => 0,
                distribution => $distribution,
            },
            took => 0,
        } )
            if !keys %$plusser_data;
        $self->get_plusser_authors( \@plusser_users )->then( sub {
            my $plusser_user_data = shift;

            $took += $plusser_user_data->{took};
            my $other_count = @plusser_users - $plusser_user_data->{total};
            my $authors     = $plusser_user_data->{authors};

            return Future->done( {
                plussers => {
                    authors      => $authors,
                    others       => $other_count,
                    distribution => $distribution,
                },
                took => $took,
            } );
        } );
        } );
}

sub get_plusser_authors {
    my ( $self, $users ) = @_;
    return Future->done( [] ) unless $users and @{$users};

    $self->request( '/author/by_user', { user => $users } );
}

__PACKAGE__->meta->make_immutable;

1;
