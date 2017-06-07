package MetaCPAN::Web::Model::API::Favorite;
use Moose;
use namespace::autoclean;

extends 'MetaCPAN::Web::Model::API';

use List::Util qw(uniq);
use Future;

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

sub get {
    my ( $self, $user, @distributions ) = @_;
    @distributions = uniq @distributions;

    # If there are no distributions this will build a query with an empty
    # filter and ES will return a parser error... so just skip it.
    if ( !@distributions ) {
        return Future->wrap( {} );
    }

    return $self->request(
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
        )->transform(
        done => sub {
            my $data = shift;
            return {
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
            };
        }
        );
}

sub by_user {
    my ( $self, $user, $size ) = @_;
    $size ||= 250;
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
    $self->request( '/favorite/recent',
        { size => $page_size, page => $page } )->then(
        sub {
            my $data = shift;
            my @user_ids = map { $_->{user} } @{ $data->{favorites} };
            return Future->done unless @user_ids;
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
                                unless
                                exists $author_for_user_id{ $fav->{user} };
                            $fav->{clicked_by_author}
                                = $author_for_user_id{ $fav->{user} };
                        }
                    }
                }
                );
        }
        );
}

sub leaderboard {
    my ($self) = @_;
    $self->request('/favorite/leaderboard');
}

sub find_plussers {
    my ( $self, $distribution ) = @_;

    # search for all users, match all according to the distribution.
    $self->by_dist($distribution)->then(
        sub {
            my $plusser_data = shift;

            # store in an array.
            my @plusser_users = map { $_->{user} }
                map { single_valued_arrayref_to_scalar( $_->{_source} ) }
                @{ $plusser_data->{hits}->{hits} };

            $self->get_plusser_authors( \@plusser_users )->then(
                sub {
                    my @plusser_authors = @{ +shift };
                    return Future->done(
                        {
                            plusser_authors => \@plusser_authors,
                            plusser_others =>
                                scalar( @plusser_users - @plusser_authors ),
                            plusser_data => $distribution
                        }
                    );
                }
            );
        }
    );

    # find plussers by pause ids.

}

sub get_plusser_authors {
    my ( $self, $users ) = @_;
    return Future->done( [] ) unless $users and @{$users};

    $self->request( '/author/by_user', undef, { user => $users } )
        ->transform(
        done => sub {
            my $res = shift;
            return [] unless $res->{authors};

            return [
                map +{
                    id  => $_->{pauseid},
                    pic => $_->{gravatar_url},
                },
                @{ $res->{authors} }
            ];
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

__PACKAGE__->meta->make_immutable;

1;
