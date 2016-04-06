package MetaCPAN::Web::Model::API::Favorite;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

use List::MoreUtils qw(uniq);

sub get {
    my ( $self, $user, @distributions ) = @_;
    @distributions = uniq @distributions;
    my $cv = $self->cv;

    # If there are no distributions this will build a query with an empty
    # filter and ES will return a parser error... so just skip it.
    if ( !@distributions ) {
        $cv->send( {} );
        return $cv;
    }

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
            aggregations => {
                favorites => {
                    terms => {
                        field => 'favorite.distribution',
                        size  => scalar @distributions,
                    },
                },
                $user
                ? (
                    myfavorites => {
                        filter => { term => { 'favorite.user' => $user } },
                        aggregations => {
                            enteries => {
                                terms => { field => 'favorite.distribution' }
                            }
                        }
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
                        map { $_->{key} => $_->{doc_count} }
                            @{ $data->{aggregations}->{favorites}->{buckets} }
                    },
                    myfavorites => $user
                    ? {
                        map { $_->{key} => $_->{doc_count} }
                            @{ $data->{aggregations}->{myfavorites}->{entries}->{buckets} }
                        }
                    : {},
                }
            );
        }
        );
    return $cv;
}

sub by_user {
    my ( $self, $user, $size ) = @_;
    $size ||= 250;
    return $self->request(
        '/favorite/_search',
        {
            query  => { match_all => {} },
            filter => { term      => { user => $user }, },
            sort   => ['distribution'],
            fields => [qw(date author distribution)],
            size   => $size,
        }
    );
}

sub recent {
    my ( $self, $page, $page_size ) = @_;
    $self->request(
        '/favorite/_search',
        {
            size  => $page_size,
            from  => ( $page - 1 ) * $page_size,
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
            aggregations => {
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
        = @plusser_users
        ? $self->plusser_by_id( \@plusser_users )->recv->{hits}->{hits}
        : [];

    my @plusser_details = map {
        {
            id  => $_->{fields}->{pauseid},
            pic => $_->{fields}->{gravatar_url},
        }
    } @{$authors};

    my $total_authors = @plusser_details;

    # find total non pauseid users who have ++ed the dist.
    my $total_nonauthors = ( $total_plussers - $total_authors );

    # number of pauseid users can be more than total plussers
    # then set 0 to non pauseid users
    $total_nonauthors = 0 if $total_nonauthors < 0;

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

1;
