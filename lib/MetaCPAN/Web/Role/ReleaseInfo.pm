package MetaCPAN::Web::Role::ReleaseInfo;

use Moose::Role;

# TODO: are there other controllers that do (or should) include this?

# TODO: should some of this be in a separate (instantiable) model
# so you don't have to keep passing $data?
# then wouldn't have to pass favorites back in.
# Role/API/Aggregator?, Model/APIAggregator/ReleaseInfo?

# add favorites and myfavorite data into $main hash
sub add_favorites_data {
    my ( $self, $main, $favorites, $data ) = @_;
    $main->{myfavorite} = $favorites->{myfavorites}->{ $data->{distribution} };
    $main->{favorites}  = $favorites->{favorites}->{   $data->{distribution} };
    return;
}

# TODO: should the api_requests be in the base controller role,
# and then the default extras be defined in other roles?

# pass in any api request condvars and combine them with these defaults
sub api_requests {
    my ( $self, $c, $reqs, $data ) = @_;

    return {
        author     => $c->model('API::Author')->get( $data->{author} ),

        favorites  => $c->model('API::Favorite')
            ->get( $c->user_exists ? $c->user->id : undef, $data->{distribution} ),

        rating     => $c->model('API::Rating')->get( $data->{distribution} ),

        versions   => $c->model('API::Release')->versions( $data->{distribution} ),
        distribution => $c->model('API::Release')->distribution( $data->{distribution} ),
        changes    => $c->model('API::Changes')->get( $data->{author}, $data->{name} ),
        %$reqs,
    };
}

# organize the api results into simple variables for the template
sub stash_api_results {
    my ( $self, $c, $reqs, $data ) = @_;

    my $changes = $c->model('API::Changes')->last_version(
        $reqs->{changes},
        $data,
    );

    $c->stash({
        author     => $reqs->{author},
        #release    => $release->{hits}->{hits}->[0]->{_source},
        rating     => $reqs->{rating}->{ratings}->{ $data->{distribution} },
        distribution => $reqs->{distribution},
        versions   =>
            [ map { $_->{fields} } @{ $reqs->{versions}->{hits}->{hits} } ],
        ( $changes ? (last_version_changes => $changes) : () ),
    });
}

# call recv() on all values in the provided hashref
sub recv_all {
    my ( $self, $condvars ) = @_;
    return { map { $_ => $condvars->{$_}->recv } keys %$condvars };
};

1;
