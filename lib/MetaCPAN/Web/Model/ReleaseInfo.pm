package MetaCPAN::Web::Model::ReleaseInfo;

use strict;
use warnings;
use Moose;

extends 'Catalyst::Model';

use Future                                        ();
use List::Util                                    qw( all );
use MetaCPAN::Web::API::RequestInfo::Orchestrator ();
use Ref::Util                                     qw( is_hashref );
use URI                                           ();
use URI::Escape qw( uri_escape uri_unescape );

my %models = (
    _distribution => 'API::Distribution',
    _release      => 'API::Release',
    _author       => 'API::Author',
    _contributors => 'API::Contributors',
    _changes      => 'API::Changes',
    _favorite     => 'API::Favorite',
    _permission   => 'API::Permission',
);

has [ keys %models ] => ( is => 'ro' );
has full_details     => ( is => 'ro' );

sub ACCEPT_CONTEXT {
    my ( $class, $c, @args ) = @_;
    @args = %{ $args[0] }
        if @args == 1 and is_hashref( $args[0] );
    push @args, map +( $_ => $c->model( $models{$_} ) ), keys %models;
    return $class->new(@args);
}

sub via_dist {
    my ( $self, $dist ) = @_;
    $self->_fetch(
        MetaCPAN::Web::API::RequestInfo::Orchestrator->new(
            model => $self->_release,
            dist  => $dist,
        ),
    );
}

sub via_release {
    my ( $self, $author, $release_name ) = @_;
    $self->_fetch(
        MetaCPAN::Web::API::RequestInfo::Orchestrator->new(
            model   => $self->_release,
            author  => $author,
            release => $release_name,
        ),
    );
}

sub _fetch {
    my ( $self, $fetch ) = @_;
    $fetch->with_release(
        sub {
            my ( $author, $release ) = @_;
            return (
                [ author => $self->_author->get($author) ],
                [
                    contributors =>
                        $self->_contributors->get( $author, $release )
                ],
                [
                    coverage => $self->_release->coverage( $author, $release )
                ],
            );
        },
    )->with_dist(
        sub {
            my ($dist) = @_;
            return (
                [ favorites    => $self->_favorite->by_dist($dist) ],
                [ plussers     => $self->_favorite->find_plussers($dist) ],
                [ versions     => $self->_release->versions($dist) ],
                [ distribution => $self->_distribution->get($dist) ],
            );
        },
    )->with_release_detail(
        sub {
            my ($release_data) = @_;
            return (
                [ notification => $self->_get_notification($release_data) ],
            );
        },
    )->then( sub {
        my ($data)  = @_;
        my $release = $data->{release};
        my $dist    = $data->{distribution};

        $data->{chat}   = $self->_get_chat( $release, $dist );
        $data->{issues} = $self->_get_issues( $release, $dist );
        $data->{github} = $data->{distribution}->{repo}->{github};
        $data->{repository} = $self->_get_repository( $release, $dist );

        Future->done($data);
    } );
}

sub find {
    my $self  = shift;
    my $fetch = $self->via_dist(@_);
    $fetch = $self->_add_details($fetch)
        if $self->full_details;
    return $fetch->fetch;
}

sub get {
    my $self  = shift;
    my $fetch = $self->via_release(@_);
    $fetch = $self->_add_details($fetch)
        if $self->full_details;
    return $fetch->fetch;
}

sub _add_details {
    my ( $self, $fetch ) = @_;

    $fetch->with_release( sub {
        my ( $author, $release ) = @_;
        return (
            [
                files =>
                    $self->_release->interesting_files( $author, $release )
            ],
            [ modules => $self->_release->modules( $author, $release ) ],
            [
                changes => $self->_changes->release_changes(
                    [ $author, $release ],
                    include_dev => 1
                )
            ],
        );
    } );
}

sub _get_repository {
    my ( $self, $release ) = @_;
    my $repo = $release->{resources}{repository}
        or return {};

    $repo = {%$repo};

    for my $type (qw(url web)) {
        my $url = $repo->{$type}
            or next;

        if (
            $url =~ m{
            \A
            (?:ssh|https?|git)://
            (?:git\@)?(?:www\.)?github\.com/
            ([^/]+/[^/]+)
            (?: /tree (?: /([^/]+)? (?:/(.*))? )? )?
        }x
            )
        {
            my ( $slug, $branch, $path ) = ( $1, $2, $3 );
            $slug =~ s/\.git\z//;
            $url = "https://github.com/$slug";

            $repo->{type} ||= 'git';
            $repo->{web}  ||= $url;
            $repo->{url}  ||= "$url.git";

            if ( $type eq 'url' ) {
                $url .= '.git';
            }
            elsif ($branch) {
                $url .= "/tree/$branch";
                if ($path) {
                    $url .= "/$path";
                }
            }
        }
        $repo->{$type} = $url;
    }

    return $repo;
}

sub _get_chat {
    my ( $self, $release ) = @_;

    my $resources = $release->{metadata}{resources};

    my $chat = $resources->{x_chat} || $resources->{x_IRC}
        or return {};

    my $chat_info = ref $chat ? {%$chat} : { url => $chat };

    if ( !$chat_info->{web} && $chat_info->{url} ) {
        my $url    = URI->new( $chat_info->{url} );
        my $scheme = $url->scheme;
        if ( !$scheme ) {
        }
        elsif ( $scheme eq 'http' || $scheme eq 'https' ) {
            $chat_info->{web} = $url->canonical->as_string;
        }
        elsif ( $scheme eq 'irc' || $scheme eq 'ircs' ) {
            my $ssl  = $scheme eq 'ircs';
            my $host = $url->authority;
            my $port;
            my $user;
            if ( $host =~ s/:(\+)?(\d+)$// ) {
                $port = $2;
                if ($1) {
                    $ssl = 1;
                }
            }
            if ( $host =~ s/^(.*)@// ) {
                $user = $1;
            }
            my $path = uri_unescape( $url->path );
            $path =~ s{^/}{};
            my $channel
                = $path || $url->fragment || $url->query_param('channel');
            $channel =~ s/^(?![#~!+])/#/;

            if ( $host eq 'libera.chat' || $host eq 'irc.libera.chat' ) {
                $chat_info->{web} = 'https://web.libera.chat/#' . $channel;
            }
            else {
                my $link
                    = 'irc://'
                    . $host
                    . (
                      $ssl  ? q{:+} . ( $port || 6697 )
                    : $port ? ":$port"
                    :         q{}
                    )
                    . '/'
                    . $channel
                    . '?nick=mc-guest-?';
                $chat_info->{web}
                    = 'https://kiwiirc.com/nextclient/#' . $link;
            }
        }
    }

    return $chat_info;
}

# Normalize issue info into a simple hashref.
# The view was getting messy trying to ensure that the issue count only showed
# when the url in the 'release' matched the url in the 'distribution'.
# If a release links to github, don't show the RT issue count.
# However, there are many ways for a release to specify RT :-/
# See t/model/issues.t for examples.

use constant RT_URL_PREFIX =>
    'https://rt.cpan.org/Public/Dist/Display.html?Name=';

sub _get_issues {
    my ( $self, $release, $distribution ) = @_;

    my $issues = {};

    my $bugtracker = ( $release->{resources} || {} )->{bugtracker} || {};

    if ( $bugtracker->{web} && $bugtracker->{web} =~ /^https?:/ ) {
        $issues->{url} = $bugtracker->{web};
    }
    elsif ( $bugtracker->{mailto} ) {
        $issues->{url} = 'mailto:' . $bugtracker->{mailto};
    }
    else {
        $issues->{url}
            = RT_URL_PREFIX . uri_escape( $release->{distribution} );
    }

    for my $bugs ( values %{ $distribution->{bugs} || {} } ) {

       # Include the active issue count, but only if counts came from the same
       # source as the url specified in the resources.
        if (
           # If the specified url matches the source we got our counts from...
            $self->normalize_issue_url( $issues->{url} ) eq
            $self->normalize_issue_url( $bugs->{source} )

            # or if both of them look like rt.
            or all {m{^https?://rt\.cpan\.org(?:/|$)}}
            ( $issues->{url}, $bugs->{source} )
            )
        {
            $issues->{active} = $bugs->{active};
        }
    }

    return $issues;
}

sub normalize_issue_url {
    my ( $self, $url ) = @_;
    $url
        =~ s{^https?:// (?:www\.)? ( github\.com / (?:[^/]+) / (?:[^/]+) ) .*$}{https://$1}x;
    $url =~ s{
        ^https?:// rt\.cpan\.org /
        (?:
            NoAuth/Bugs\.html\?Dist=
        |
            (?:Public/)?Dist/Display\.html\?Name=
        )
    }{https://rt.cpan.org/Dist/Display.html?Name=}x;

    return $url;
}

sub _get_notification {
    my ( $self, $release ) = @_;
    my $module = $release->{main_module};
    $self->_permission->get_notification_info($module)->then( sub {
        my $data = shift;

        # Unless we already have Notifications from Permissions, see if there
        # are others needing to be added.
        unless ( $data->{notification} ) {
            if ( $release->{deprecated} ) {
                $data->{notification} = { type => 'DEPRECATED' };
            }
        }

        # Return the Notifications (either Permission based, or for Deprecated
        # status).
        return Future->done($data);
    } );
}

__PACKAGE__->meta->make_immutable;
1;
