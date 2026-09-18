package MetaCPAN::Web::Model::API::Author;

use Moose;
use namespace::autoclean;

use Future                     ();
use MetaCPAN::Web::ProfileLink ();
use Ref::Util                  qw( is_arrayref );

extends 'MetaCPAN::Web::Model::API';

=head1 NAME

MetaCPAN::Web::Model::Author - Catalyst Model

=head1 DESCRIPTION

Catalyst Model.

=head1 AUTHOR

Matthew Phillips

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

sub _filter_authors {
    my $data = shift;
    my $authors
        = exists $data->{authors} ? $data->{authors}
        : exists $data->{author}  ? [ $data->{author} ]
        :                           [];
    for my $author (@$authors) {
        my $display_name
            = defined $author->{display_name}        ? $author->{display_name}
            : ( $author->{name} // '' ) =~ /\w/      ? $author->{name}
            : ( $author->{asciiname} // '' ) =~ /\w/ ? $author->{asciiname}
            : defined $author->{pauseid}             ? $author->{pauseid}
            :                                          undef;
        if ( defined $display_name ) {
            $author->{display_name} = $display_name;
            $author->{has_display_name}
                = $author->{display_name} ne ( $author->{pauseid} // '' );
        }
    }
    return Future->done($data);
}

sub get {
    my ( $self, $author ) = @_;

    return $self->request( '/author/' . uc($author) )->then( sub {
        my $data = shift;
        if ( $data->{code} ) {
            return Future->done($data);
        }
        else {
            return Future->done( { author => $data } );
        }
    } )->then( \&_filter_authors );
}

sub get_multiple {
    my ( $self, @authors ) = @_;
    return Future->done( { took => 0, total => 0, authors => [] } )
        if !@authors;
    return $self->request( '/author/by_ids', { id => [ map uc, @authors ] } )
        ->transform(
        done => sub {
            my $data = shift;
            my %authors;
            $authors{ $_->{pauseid} } = $_ for @{ $data->{authors} };
            $data->{authors} = [ @authors{@authors} ];
            $data;
        }
        )->then( \&_filter_authors );
}

sub search {
    my ( $self, $query, $from ) = @_;
    return $self->request( '/author/search', undef,
        { q => $query, from => $from } )->then( \&_filter_authors );
}

sub by_user {
    my ( $self, $users ) = @_;
    return Future->done( [] ) unless $users;

    my $ret;
    if ( is_arrayref($users) ) {
        return unless @{$users};
        $ret = $self->request( '/author/by_user', undef, { user => $users } );
    }
    else {
        $ret = $self->request("/author/by_user/$users");
    }
    $ret->transform(
        done => sub {
            my $data = shift;
            return { authors => [] }
                if !exists $data->{authors};
            $data;
        }
    )->then( \&_filter_authors );
}

my $profile_data = {
    bitbucket => {
        url_format => 'https://bitbucket.org/%s',
    },
    bluesky => {
        url_format => 'https://bsky.app/profile/%s',
        icon       => '/static/images/profile/bluesky.svg',
    },
    codeberg => {
        url_format => 'https://codeberg.org/%s',
    },
    coderwall => {
        url_format => 'https://coderwall.com/%s',
    },
    couchsurfing => {
        label      => 'Couch Surfing',
        url_format => 'https://www.couchsurfing.org/people/%s/',
    },
    dotshare => {
        url_format => 'http://dotshare.it/~%s/',
    },
    facebook => {
        url_format => 'https://www.facebook.com/%s',
    },
    flickr => {
        url_format => 'https://www.flickr.com/people/%s/',
    },
    github => {
        label      => 'GitHub',
        url_format => 'https://github.com/%s',
    },
    gitlab => {
        label      => 'GitLab',
        url_format => 'https://gitlab.com/%s',
    },
    hackernews => {
        label      => 'Hacker News',
        url_format => 'https://news.ycombinator.com/user?id=%s',
    },
    hackerrank => {
        label      => 'HackerRank',
        url_format => 'https://www.hackerrank.com/profile/%s',
    },
    hackthissite => {
        label      => 'HackThisSite',
        url_format => 'https://www.hackthissite.org/user/view/%s',
    },
    identica => {
        label      => 'Identi.ca',
        url_format => 'https://identi.ca/%s',
    },
    instagram => {
        url_format => 'https://www.instagram.com/%s/',
    },
    lastfm => {
        label      => 'LastFM',
        url_format => 'https://www.last.fm/user/%s',
    },
    linkedin => {
        label      => 'LinkedIn',
        url_format => 'https://www.linkedin.com/in/%s',
    },
    mastodon => {
        rule       => '@([a-z0-9_]+([.-]+[a-z0-9_]+)*)@([\w-]+(\.[\w-]+))',
        url_format => 'https://%3$s/@%1$s',
        icon       => '/static/images/profile/mastodon.svg',
    },
    meetup => {
        url_format => 'https://www.meetup.com/members/%s',
    },
    myspace => {
        label      => 'MySpace',
        url_format => 'https://www.myspace.com/%s',
    },
    newsblur => {
        label      => 'Newsblur',
        url_format => 'https://%s.newsblur.com/',
    },
    ohloh => {
        label      => 'Open Hub',
        url_format => 'https://www.openhub.net/accounts/%s',
    },
    orcid => {
        label      => 'ORCID iD',
        url_format => 'https://orcid.org/%s',
    },
    perlmonks => {
        label      => 'PerlMonks',
        url_format => 'https://www.perlmonks.org/?node=%s',
    },
    pinboard => {
        url_format => 'https://pinboard.in/u:%s',
    },
    reddit => {
        url_format => 'https://www.reddit.com/user/%s',
    },
    slideshare => {
        label      => 'SlideShare',
        url_format => 'https://www.slideshare.net/%s',
    },
    sourceforge => {
        label      => 'SourceForge',
        url_format => 'https://sourceforge.net/users/%s',
    },
    speakerdeck => {
        label      => 'SpeakerDeck',
        url_format => 'https://speakerdeck.com/u/%s',
    },
    stackexchange => {
        label      => 'StackExchange',
        url_format => 'https://stackexchange.com/users/%s?tab=accounts',
    },
    stackoverflow => {
        label      => 'StackOverflow',
        url_format => 'https://stackoverflow.com/users/%s/',
    },
    stackoverflowcareers => {
        label      => 'Stack Overflow Careers',
        url_format => 'https://careers.stackoverflow.com/%s',
    },
    steam => {
        url_format => 'https://steamcommunity.com/id/%s',
    },
    stumbleupon => {
        label      => 'StumbleUpon',
        url_format => 'https://www.stumbleupon.com/stumbler/%s/',
    },
    substack => {
        url_format => 'https://%s.substack.com/',
    },
    tumblr => {
        url_format => 'http://%s.tumblr.com/',
    },
    twitter => {
        url_format => 'https://twitter.com/%s',
    },
    vimeo => {
        url_format => 'https://vimeo.com/%s',
    },
    youtube => {
        url_format => 'https://www.youtube.com/@%s',
    },
};

for my $name ( keys %$profile_data ) {
    my $data    = $profile_data->{$name};
    my $profile = MetaCPAN::Web::ProfileLink->new(
        name => $name,
        %$data,
    );
    $profile_data->{$name} = $profile;
}

sub profile_data {
    my ($self) = @_;
    return $profile_data;
}

__PACKAGE__->meta->make_immutable;

1;
