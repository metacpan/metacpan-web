package MetaCPAN::Web::Model::API::Author;

use Moose;
use namespace::autoclean;

use Future      ();
use Ref::Util   qw( is_arrayref );
use URI::Escape qw( uri_escape );

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
        name       => 'Bitbucket',
        url_format => 'https://bitbucket.org/%s',
    },
    coderwall => {
        name       => 'Coderwall',
        url_format => 'https://coderwall.com/%s',
    },
    couchsurfing => {
        name       => 'Couch Surfing',
        url_format => 'https://www.couchsurfing.org/people/%s/',
    },
    dotshare => {
        name       => 'Dotshare',
        url_format => 'http://dotshare.it/~%s/',
    },
    facebook => {
        name       => 'Facebook',
        url_format => 'https://www.facebook.com/%s',
    },
    flickr => {
        name       => 'Flickr',
        url_format => 'https://www.flickr.com/people/%s/',
    },
    github => {
        name       => 'GitHub',
        url_format => 'https://github.com/%s',
    },
    gitlab => {
        name       => 'GitLab',
        url_format => 'https://gitlab.com/%s',
    },
    hackernews => {
        name       => 'Hacker News',
        url_format => 'https://news.ycombinator.com/user?id=%s',
    },
    hackerrank => {
        name       => 'HackerRank',
        url_format => 'https://www.hackerrank.com/profile/%s',
    },
    hackthissite => {
        name       => 'HackThisSite',
        url_format => 'https://www.hackthissite.org/user/view/%s',
    },
    identica => {
        name       => 'Identi.ca',
        url_format => 'https://identi.ca/%s',
    },
    instagram => {
        name       => 'Instagram',
        url_format => 'https://www.instagram.com/%s/',
    },
    lastfm => {
        name       => 'LastFM',
        url_format => 'https://www.last.fm/user/%s',
    },
    linkedin => {
        name       => 'LinkedIn',
        url_format => 'https://www.linkedin.com/in/%s',
    },
    meetup => {
        name       => 'Meetup',
        url_format => 'https://www.meetup.com/members/%s',
    },
    myspace => {
        name       => 'MySpace',
        url_format => 'https://www.myspace.com/%s',
    },
    newsblur => {
        name       => 'Newsblur',
        url_format => 'https://%s.newsblur.com/',
    },
    ohloh => {
        name       => 'Open Hub',
        url_format => 'https://www.openhub.net/accounts/%s',
    },
    orcid => {
        name       => 'ORCID iD',
        url_format => 'https://orcid.org/%s',
    },
    perlmonks => {
        name       => 'PerlMonks',
        url_format => 'https://www.perlmonks.org/?node=%s',
    },
    pinboard => {
        name       => 'Pinboard',
        url_format => 'https://pinboard.in/u:%s',
    },
    reddit => {
        name       => 'Reddit',
        url_format => 'https://www.reddit.com/user/%s',
    },
    slideshare => {
        name       => 'SlideShare',
        url_format => 'https://www.slideshare.net/%s',
    },
    sourceforge => {
        name       => 'SourceForge',
        url_format => 'https://sourceforge.net/users/%s',
    },
    speakerdeck => {
        name       => 'SpeakerDeck',
        url_format => 'https://speakerdeck.com/u/%s',
    },
    stackexchange => {
        name       => 'StackExchange',
        url_format => 'https://stackexchange.com/users/%s?tab=accounts',
    },
    stackoverflow => {
        name       => 'StackOverflow',
        url_format => 'https://stackoverflow.com/users/%s/',
    },
    stackoverflowcareers => {
        name       => 'Stack Overflow Careers',
        url_format => 'https://careers.stackoverflow.com/%s',
    },
    steam => {
        name       => 'Steam',
        url_format => 'https://steamcommunity.com/id/%s',
    },
    stumbleupon => {
        name       => 'StumbleUpon',
        url_format => 'https://www.stumbleupon.com/stumbler/%s/',
    },
    substack => {
        name       => 'Substack',
        url_format => 'https://%s.substack.com/',
    },
    tumblr => {
        name       => 'Tumblr',
        url_format => 'http://%s.tumblr.com/',
    },
    twitter => {
        name       => 'Twitter',
        url_format => 'https://twitter.com/%s',
    },
    vimeo => {
        name       => 'Vimeo',
        url_format => 'https://vimeo.com/%s',
    },
    youtube => {
        name       => 'Youtube',
        url_format => 'https://www.youtube.com/user/%s',
    },
};

for my $profile ( keys %$profile_data ) {
    my $data = $profile_data->{$profile};
    $data->{icon} //= "/static/images/profile/$profile.png";
    my $url_format = $data->{url_format};
    $data->{url_for} = sub {
        my ($id) = @_;
        sprintf $url_format, uri_escape($id);
    };
}

sub profile_data {
    my ($self) = @_;
    return $profile_data;
}

__PACKAGE__->meta->make_immutable;

1;
