package MetaCPAN::Web::Model::ReleaseInfo;

use Moose;
use namespace::autoclean;

use URI;
use URI::Escape qw(uri_escape uri_unescape);
use URI::QueryParam;    # Add methods to URI.

extends 'Catalyst::Model';

use List::AllUtils qw( all );

sub ACCEPT_CONTEXT {
    my ( $class, $c, $args ) = @_;
    return $class->new(
        {
            c => $c,
            %$args,
        }
    );
}

has c            => ( is => 'ro', );
has author       => ( is => 'ro', );
has release      => ( is => 'ro', );
has distribution => ( is => 'ro', );

sub summary_hash {
    my ($self) = @_;
    return {
        contributors => $self->groom_contributors,
        irc          => $self->groom_irc,
        issues       => $self->normalize_issues,
    };
}

# massage the x_contributors field into what we want
sub groom_contributors {
    my ($self) = @_;
    my ( $release, $author ) = ( $self->release, $self->author );

    my $contribs = $release->{metadata}{x_contributors} || [];
    my $authors  = $release->{metadata}{author}         || [];

    for ( \( $contribs, $authors ) ) {

        # If a sole contributor is a string upgrade it to an array...
        $$_ = [$$_]
            if !ref $$_;

        # but if it's any other kind of value don't die trying to parse it.
        $$_ = []
            if ref($$_) ne 'ARRAY';
    }

    $authors = [ grep { $_ ne 'unknown' } @$authors ];

    my $author_info = {
        email =>
            [ lc "$release->{author}\@cpan.org", @{ $author->{email} }, ],
        name => $author->{name},
    };
    my %seen = map { $_ => $author_info }
        ( @{ $author_info->{email} }, $author_info->{name}, );

    my @contribs = map {
        my $name = $_;
        my $email;
        if ( $name =~ s/\s*<([^<>]+@[^<>]+)>// ) {
            $email = $1;
        }
        my $info;
        my $dupe;
        if ( $email and $info = $seen{$email} ) {
            $dupe = 1;
        }
        elsif ( $info = $seen{$name} ) {
            $dupe = 1;
        }
        else {
            $info = {
                name  => $name,
                email => [],
            };
        }
        $seen{$name} ||= $info;
        if ($email) {
            push @{ $info->{email} }, $email
                unless grep { $_ eq $email } @{ $info->{email} };
            $seen{$email} ||= $info;
        }
        $dupe ? () : $info;
    } ( @$authors, @$contribs );

    for my $contrib (@contribs) {

        # heuristic to autofill pause accounts
        if ( !$contrib->{pauseid} ) {
            my ($pauseid)
                = map { /^(.*)\@cpan\.org$/ ? $1 : () }
                @{ $contrib->{email} };
            $contrib->{pauseid} = uc $pauseid
                if $pauseid;
        }

        if ( $contrib->{pauseid} ) {
            $contrib->{url}
                = $self->c->uri_for_action( '/author/index',
                [ $contrib->{pauseid} ] );
        }
    }

    return \@contribs;
}

sub groom_irc {
    my ($self) = @_;

    my $irc = $self->release->{metadata}{resources}{x_IRC};
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

            if ( $host =~ /(?:^|\.)freenode\.net$/ ) {
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

# Normalize issue info into a simple hashref.
# The view was getting messy trying to ensure that the issue count only showed
# when the url in the 'release' matched the url in the 'distribution'.
# If a release links to github, don't show the RT issue count.
# However, there are many ways for a release to specify RT :-/
# See t/model/issues.t for examples.

sub rt_url_prefix {
    'https://rt.cpan.org/Public/Dist/Display.html?Name=';
}

sub normalize_issues {
    my ($self) = @_;
    my ( $release, $distribution ) = ( $self->release, $self->distribution );

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
            = $self->rt_url_prefix . uri_escape( $release->{distribution} );
    }

    if ( my $bugs = $distribution->{bugs} ) {

       # Include the active issue count, but only if counts came from the same
       # source as the url specified in the resources.
        if (
           # If the specified url matches the source we got our counts from...
            $self->normalize_issue_url( $issues->{url} ) eq
            $self->normalize_issue_url( $bugs->{source} )

            # or if both of them look like rt.
            or all {m{^https?://rt\.cpan\.org(/|$)}}
            ( $issues->{url}, $bugs->{source} )
            )
        {
            $issues->{active} = $bugs->{active};
        }
    }

    return $issues;
}

sub normalize_issue_url {
    local $_ = $_[1];

    s{^https?:// (?:www\.)? ( github\.com / ([^/]+) / ([^/]+) ) (.*)$}{https://$1}x;

    return $_;
}

__PACKAGE__->meta->make_immutable;

1;
