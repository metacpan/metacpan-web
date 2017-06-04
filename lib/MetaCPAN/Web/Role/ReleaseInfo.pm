package MetaCPAN::Web::Role::ReleaseInfo;

use Moose::Role;

use Importer 'MetaCPAN::Web::Elasticsearch::Adapter' =>
    qw/ single_valued_arrayref_to_scalar /;

# TODO: are there other controllers that do (or should) include this?

# TODO: should some of this be in a separate (instantiable) model
# so you don't have to keep passing $data?
# then wouldn't have to pass favorites back in.
# Role/API/Aggregator?, Model/APIAggregator/ReleaseInfo?

# add favorites and myfavorite data into $main hash
sub add_favorites_data {
    my ( $self, $main, $favorites, $data ) = @_;
    $main->{myfavorite}
        = $favorites->{myfavorites}->{ $data->{distribution} };
    $main->{favorites} = $favorites->{favorites}->{ $data->{distribution} };
    return;
}

# TODO: should the api_requests be in the base controller role,
# and then the default extras be defined in other roles?

# pass in any api request condvars and combine them with these defaults
sub api_requests {
    my ( $self, $c, $reqs, $data ) = @_;

    return {
        author => $c->model('API::Author')->get( $data->{author} ),

        favorites => $c->model('API::Favorite')->get(
            $c->user_exists ? $c->user->id : undef,
            $data->{distribution}
        ),

        contributors => $c->model('API::Contributors')
            ->get( $data->{author}, $data->{release} ),

        rating => $c->model('API::Rating')->get( $data->{distribution} ),

        distribution =>
            $c->model('API::Release')->distribution( $data->{distribution} ),

        %$reqs,
    };
}

# organize the api results into simple variables for the template
sub stash_api_results {
    my ( $self, $c, $reqs, $data ) = @_;

    my %to_stash = (
        author       => $reqs->{author},
        distribution => $reqs->{distribution},
        rating       => $reqs->{rating}->{ratings}->{ $data->{distribution} },
    );

    my %stash
        = map { $_ => single_valued_arrayref_to_scalar( $to_stash{$_} ) }
        ( 'rating', 'distribution' );

    $stash{contributors} = $reqs->{contributors};

    $c->stash( \%stash );
}

# call recv() on all values in the provided hashref
sub recv_all {
    my ( $self, $condvars ) = @_;
    return +{ map { $_ => $condvars->{$_}->recv } keys %$condvars };
}

1;
