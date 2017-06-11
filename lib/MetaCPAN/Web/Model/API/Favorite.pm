package MetaCPAN::Web::Model::API::Favorite;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

use List::Util qw(uniq);

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

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
                terms => { 'distribution' => \@distributions }
            },
            aggregations => {
                favorites => {
                    terms => {
                        field => 'distribution',
                        size  => scalar @distributions,
                    },
                },
                $user
                ? (
                    myfavorites => {
                        filter       => { term => { 'user' => $user } },
                        aggregations => {
                            enteries => {
                                terms => { field => 'distribution' }
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
                        map { $_->{key} => $_->{doc_count} } @{
                            $data->{aggregations}->{myfavorites}->{entries}
                                ->{buckets}
                        }
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
    my $ret = $self->request( "/favorite/by_user/$user", { size => $size } );
    return unless $ret;
    my $data = $ret->recv;
    return [] unless exists $data->{favorites};
    return $data->{favorites};
}

sub recent {
    my ( $self, $page, $page_size ) = @_;
    my $data = $self->request( '/favorite/recent',
        { size => $page_size, page => $page } )->recv;

    my @user_ids = map { $_->{user} } @{ $data->{favorites} };
    return $data unless @user_ids;

    my $authors
        = $self->request( '/author/by_user', undef, { user => \@user_ids } )
        ->recv;
    if ( $authors and exists $authors->{authors} ) {
        my %author_for_user_id
            = map { $_->{user} => $_->{pauseid} } @{ $authors->{authors} };
        for my $fav ( @{ $data->{favorites} } ) {
            next unless exists $author_for_user_id{ $fav->{user} };
            $fav->{clicked_by_author} = $author_for_user_id{ $fav->{user} };
        }
    }

    return $data;
}

sub leaderboard {
    my ($self) = @_;
    my $data = $self->request('/favorite/leaderboard')->recv;
    return $data;
}

sub find_plussers {
    my ( $self, $distribution ) = @_;

    # search for all users, match all according to the distribution.
    my $plusser      = $self->by_dist($distribution);
    my $plusser_data = $plusser->recv;

    # store in an array.
    my @plusser_users = map { $_->{user} }
        map { single_valued_arrayref_to_scalar( $_->{_source} ) }
        @{ $plusser_data->{hits}->{hits} };
    my $total_plussers = @plusser_users;

    # find plussers by pause ids.
    my $authors
        = @plusser_users
        ? $self->plusser_by_id( \@plusser_users )->recv->{hits}->{hits}
        : [];

    my @plusser_details = map {
        {
            id  => $_->{_source}->{pauseid},
            pic => $_->{_source}->{gravatar_url},
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
            query   => { term => { distribution => $distribution } },
            _source => "user",
            size    => 1000,
        }
    );
}

# finding the authors who have ++ed the distribution.
sub plusser_by_id {
    my ( $self, $users ) = @_;
    return $self->request(
        '/author/_search',
        {
            query => { terms => { user => $users } },
            _source => { includes => [qw(pauseid gravatar_url)] },
            size    => 1000,
            sort    => ['pauseid']
        }
    );
}

__PACKAGE__->meta->make_immutable;

1;
