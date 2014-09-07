package MetaCPAN::Web::Role::ReleaseInfo;

use Moose::Role;
use URI;
use URI::Escape qw(uri_escape uri_unescape);
use URI::QueryParam;

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

        rating => $c->model('API::Rating')->get( $data->{distribution} ),

        versions =>
            $c->model('API::Release')->versions( $data->{distribution} ),
        distribution =>
            $c->model('API::Release')->distribution( $data->{distribution} ),
        %$reqs,
    };
}

# organize the api results into simple variables for the template
sub stash_api_results {
    my ( $self, $c, $reqs, $data ) = @_;

    $c->stash(
        {
            author => $reqs->{author},

            #release    => $release->{hits}->{hits}->[0]->{_source},
            rating => $reqs->{rating}->{ratings}->{ $data->{distribution} },
            distribution => $reqs->{distribution},
            versions     => [
                map { $_->{fields} } @{ $reqs->{versions}->{hits}->{hits} }
            ],
        }
    );
}

# call recv() on all values in the provided hashref
sub recv_all {
    my ( $self, $condvars ) = @_;
    return { map { $_ => $condvars->{$_}->recv } keys %$condvars };
}

# massage the x_contributors field into what we want
sub groom_contributors {
    my ( $self, $c, $release ) = @_;

    my $contribs = $release->{metadata}{x_contributors} || [];
    my $authors  = $release->{metadata}{author}         || [];

    # just in case a lonely contributor makes it as a scalar
    $contribs = [$contribs]
        if !ref $contribs;
    $authors = [$authors]
        if !ref $authors;

    my %seen = ( lc "$release->{author}\@cpan.org" => 1, );
    my @contribs;

    for my $contrib ( @$authors, @$contribs ) {
        my $name = $contrib;
        $name =~ s/\s*<([^<>]+@[^<>]+)>//;
        my $info = {
            name => $name,
            $1 ? ( email => $1 ) : (),
        };

        next if not $info->{email};
        next
            if $seen{ $info->{email} }++;

        # heuristic to autofill pause accounts
        if (   !$info->{pauseid}
            and $info->{email} =~ /^(.*)\@cpan\.org$/ )
        {
            $info->{pauseid} = uc $1;
        }

        if ( $info->{pauseid} ) {
            $info->{url}
                = $c->uri_for_action( '/author/index', [ $info->{pauseid} ] );
        }
        push @contribs, $info;
    }

    return \@contribs;
}

sub groom_irc {
    my ( $self, $c, $release ) = @_;

    my $irc = $release->{metadata}{resources}{x_IRC};
    my $irc_info = ref $irc ? {%$irc} : { url => $irc };

    if ( !$irc_info->{web} && $irc_info->{url} ) {
        my $url    = URI->new( $irc_info->{url} );
        my $scheme = $url->scheme;
        if ( $scheme && ( $scheme eq 'irc' || $scheme eq 'ircs' ) ) {
            my $ssl  = $scheme eq 'ircs';
            my $host = $url->authority;
            my $port;
            my $user;
            if ( $host =~ s/:(\d+)$// ) {
                $port = $1;
            }
            if ( $host =~ s/^(.*)@// ) {
                $user = $1;
            }
            my $path = uri_unescape( $url->path );
            $path =~ s{^/}{};
            my $channel
                = $path || $url->fragment || $url->query_param('channel');
            $channel =~ s/^(?![#~!+])/#/;
            $channel = uri_escape($channel);

            if ( $host eq 'freenode.net' ) {
                $irc_info->{web}
                    = "https://webchat.freenode.net/?randomnick=1&prompt=1&channels=${channel}";
            }
            else {
                my $server = $host
                    . (
                      $ssl ? q{:+} . ( $port || 6697 )
                    : $port ? ":$port"
                    :         q{}
                    );
                $irc_info->{web}
                    = "https://chat.mibbit.com/?channel=${channel}&server=${server}";
            }
        }
    }

    return $irc_info;
}

1;
