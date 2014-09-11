package MetaCPAN::Web::Model::API::Favorite;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

use List::MoreUtils qw(uniq);

sub get {
    my ( $self, $user, @distributions ) = @_;
    @distributions = uniq @distributions;
    my $cv = $self->cv;
    $self->request(
        '/favorite/_search',
        {
            size  => 0,
            query => {
                filtered => {
                    query  => { match_all => {} },
                    filter => {
                        or => [
                            map {
                                { term => { 'favorite.distribution' => $_ } }
                            } @distributions
                        ]
                    }
                }
            },
            facets => {
                favorites => {
                    terms => {
                        field => 'favorite.distribution',
                        size  => scalar @distributions,
                    },
                },
                $user
                ? (
                    myfavorites => {
                        terms => { field => 'favorite.distribution', },
                        facet_filter =>
                            { term => { 'favorite.user' => $user } }
                    }
                    )
                : (),
            }
        }
        )->cb(
        sub {
            my $data = shift->recv;
            $cv->send(
                {
                    took      => $data->{took},
                    favorites => {
                        map { $_->{term} => $_->{count} }
                            @{ $data->{facets}->{favorites}->{terms} }
                    },
                    myfavorites => $user
                    ? {
                        map { $_->{term} => $_->{count} }
                            @{ $data->{facets}->{myfavorites}->{terms} }
                        }
                    : {},
                }
            );
        }
        );
    return $cv;
}

sub by_user {
    my ( $self, $user ) = @_;
    return $self->request(
        '/favorite/_search',
        {
            query  => { match_all => {} },
            filter => { term      => { user => $user }, },
            sort   => ['distribution'],
            fields => [qw(date author distribution)],
            size   => 250,
        }
    );
}

sub recent {
    my ( $self, $page ) = @_;
    $self->request(
        '/favorite/_search',
        {
            size  => 100,
            from  => ( $page - 1 ) * 100,
            query => { match_all => {} },
            sort  => [ { 'date' => { order => 'desc' } } ]
        }
    );
}

sub leaderboard {
    my ( $self, $page ) = @_;
    $self->request(
        '/favorite/_search',
        {
            size   => 0,
            query  => { match_all => {} },
            facets => {
                leaderboard =>
                    { terms => { field => 'distribution', size => 600 }, },
            },
        }
    );
}

sub find_plussers {
    my ( $self, $distribution ) = @_;

    # search for all users, match all according to the distribution.
    my $plusser      = $self->by_dist($distribution);
    my $plusser_data = $plusser->recv;

    # store in an array.
    my @plusser_users
        = map { $_->{fields}->{user} } @{ $plusser_data->{hits}->{hits} };
    my $total_plussers = @plusser_users;

    # find plussers by pause ids.
    my $authors
        = $self->plusser_by_id( \@plusser_users )->recv->{hits}->{hits};

    my @plusser_details = map {
        {
            id  => $_->{fields}->{pauseid},
            pic => $_->{fields}->{gravatar_url},
        }
    } @{$authors};

    my $total_authors = @plusser_details;

    # find total non pauseid users who have ++ed the dist.
    my $total_nonauthors = ( $total_plussers - $total_authors );

    return (
        {
            plusser_authors => \@plusser_details,
            plusser_others  => $total_nonauthors,
            plusser_data    => $distribution
        }
    );

}

# to search for v0/favorite/_search/{user} for the particular $distribution.
sub by_dist {
    my ( $self, $distribution ) = @_;
    return $self->request(
        '/favorite/_search',
        {
            query  => { match_all => {} },
            filter => { term      => { distribution => $distribution }, },
            fields => [qw(user)],
            size   => 1000,
        }
    );
}

# finding the authors who have ++ed the distribution.
sub plusser_by_id {
    my ( $self, $users ) = @_;
    return $self->request(
        '/author/_search',
        {
            query => { match_all => {} },
            filter =>
                { or => [ map { { term => { user => $_ } } } @{$users} ] },
            fields => [qw(pauseid gravatar_url)],
            size   => 1000,
            sort   => ['pauseid']
        }
    );
}

__PACKAGE__->meta->make_immutable;
