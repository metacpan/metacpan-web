package MetaCPAN::Web::Controller::Feed;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use DateTime             ();
use HTML::Escape         qw( escape_html );
use MetaCPAN::Web::Types qw( ArrayRef DateTime Enum HashRef Str Undef Uri );
use Params::ValidationCompiler qw( validation_for );
use XML::FeedPP                ();                     ## no perlimports
use URI                        ();

sub recent_rdf : Path('/recent.rdf') Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'recent', ['rdf'] );
}

sub recent_rss : Path('/recent.rss') Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'recent', ['rss'] );
}

sub recent_atom : Path('/recent.atom') Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'recent', ['atom'] );
}

sub recent : Private {
    my ( $self, $c, $type ) = @_;

    # Set surrogate key and ttl from here as well
    $c->forward('/recent/index');
    die join "\n", @{ $c->error } if @{ $c->error };

    my $changes
        = $c->model('API::Changes')
        ->by_releases(
        [ map "$_->{author}/$_->{name}", @{ $c->stash->{recent} } ] )
        ->get;

    for ( @{ $c->stash->{recent} } ) {

        # Provided in Model/API/Changes.pm Line 67
        my $k = $_->{author} . '/' . $_->{name};
        $_->{changes} = $changes->{$k};
    }

    $c->stash->{feed} = $self->build_feed(
        format  => $type,
        entries => $c->stash->{recent},
        host    => URI->new( $c->config->{web_host} ),
        title   => 'Recent CPAN uploads - MetaCPAN',
        link    => '/recent',
        date    => DateTime::->now,
    );
}

sub author_rss : Chained('/author/root') PathPart('activity.rss') Args(0) {
    $_[1]->detach( 'author', ['rss'] );
}

sub author_atom : Chained('/author/root') PathPart('activity.atom') Args(0) {
    $_[1]->detach( 'author', ['atom'] );
}

sub author : Private {
    my ( $self, $c, $type ) = @_;

    my $author = $c->stash->{pauseid};

    $c->browser_max_age('1h');
    $c->cdn_max_age('1y');

    my $author_info = $c->model('API::Author')->get($author)->get;

    # If the author can be found, we get the hashref of author info.  If it
    # can't be found, we (confusingly) get a HashRef with "code" and "message"
    # keys.

    if ( $author_info->{code} && $author_info->{code} == 404 ) {
        $c->detach( '/not_found', [] );
    }

    my $user = $author_info->{author}->{user};

    my $releases = $c->model('API::Release')->latest_by_author($author)->get;

    my $faves = $c->model('API::Favorite')->by_user($user)->get;

    $c->stash->{feed} = $self->build_feed(
        format  => $type,
        host    => $c->config->{web_host},
        title   => "Recent CPAN activity of $author - MetaCPAN",
        entries => [
            sort { $b->{date} cmp $a->{date} }
                @{ $self->_format_release_entries( $releases->{releases} ) },
            @{ $self->_format_favorite_entries( $author, $faves ) }
        ],
    );
}

sub dist_rss : Chained('/dist/root') PathPart('releases.rss') Args(0) {
    $_[1]->detach( 'dist', ['rss'] );
}

sub dist_atom : Chained('/dist/root') PathPart('releases.atom') Args(0) {
    $_[1]->detach( 'dist', ['atom'] );
}

sub dist : Private {
    my ( $self, $c ) = @_;
    my $dist = $c->stash->{distribution_name};

    $c->browser_max_age('1h');
    $c->cdn_max_age('1y');
    $c->add_dist_key($dist);

    my $data = $c->model('API::Release')->versions($dist)->get;

    $c->stash->{feed} = $self->build_feed(
        format  => $c->req->params->{'type'},
        host    => $c->config->{web_host},
        title   => "Recent CPAN uploads of $dist - MetaCPAN",
        entries => $data->{versions},
    );
}

my $feed_check = validation_for(
    params => {
        entries => { type => ArrayRef [HashRef] },
        host    => { type => Uri, optional => 0, },
        title   => { type => Str },
        link    => {
            type    => Uri,
            default => '/',
        },
        date => {
            type     => DateTime,
            optional => 1,
        },
        description => {
            type     => Str,
            optional => 1,
        },
        format => {
            type => Enum( [qw(atom rdf rss)] )
                ->plus_coercions( Undef, '"rdf"', Str, 'lc $_' ),
            default => 'rdf'
        },
    },
);

sub build_entry {
    my ( $self, %args ) = @_;
    my $entry = $args{entry};
    my $e     = $args{class}->new;

    my $link = $args{host}->clone;
    $link->path( $entry->{link}
            || join( '/', 'release', $entry->{author}, $entry->{name} ) );
    $link->fragment( $entry->{fragment} ) if $entry->{fragment};    # for news
    $e->link( $link->as_string );

    $e->author( $entry->{author} );
    $e->pubDate( $entry->{date} );
    $e->title( $entry->{name} );

    my $content = escape_html( $entry->{abstract} // q{} );

    if ( my $changelog = $entry->{changes} ) {
        if ($content) {
            $content = "<p>$content</p>";
        }
        $content .= '<p>Changes for ' . escape_html( $changelog->{version} );
        if ( $changelog->{date} ) {
            $content .= ' - ' . escape_html( $changelog->{date} );
        }
        $content .= '</p><ul>';
        for my $entry ( @{ $changelog->{entries} } ) {
            $content .= '<li>' . escape_html( $entry->{text} ) . "</li>\n";
        }
        $content .= '</ul>';
    }
    $e->description($content);

    return $e;
}

sub build_feed {
    my $self   = shift;
    my %params = $feed_check->(@_);

    my $feed_class
        = $params{format} eq 'rdf'  ? XML::FeedPP::RDF::
        : $params{format} eq 'rss'  ? XML::FeedPP::RSS::
        : $params{format} eq 'atom' ? XML::FeedPP::Atom::Atom10::
        :                             die 'invalid format';

    my $feed = $feed_class->new;
    $feed->title( $params{title} );
    $feed->link("$params{link}");
    $feed->pubDate( $params{date}->iso8601 )
        if $params{date};
    $feed->description( $params{description} )
        if $params{description};

    foreach my $entry ( @{ $params{entries} } ) {
        $feed->add_item( $self->build_entry(
            class => $feed->item_class,
            entry => $entry,
            host  => $params{host},
        ) );
    }
    return $feed;
}

sub _format_release_entries {
    my ( $self, $releases ) = @_;
    my @release_data;
    foreach my $item ( @{$releases} ) {
        $item->{link}
            = join( '/', 'release', $item->{author}, $item->{name} );
        $item->{name} = "$item->{author} has released $item->{name}";
        push( @release_data, $item );
    }
    return \@release_data;
}

sub _format_favorite_entries {
    my ( $self, $author, $data ) = @_;
    my @fav_data;
    foreach my $fav ( @{$data} ) {
        $fav->{abstract}
            = "$author ++ed $fav->{distribution} from $fav->{author}";
        $fav->{author} = $author;
        $fav->{link}   = join( '/', 'release', $fav->{distribution} );
        $fav->{name}   = "$author ++ed $fav->{distribution}";
        push( @fav_data, $fav );
    }
    return \@fav_data;
}

sub end : Private {
    my ( $self, $c ) = @_;
    my $feed = $c->stash->{feed};
    $c->detach('/end')
        if !$feed;

# This will only affect if `cdn_max_age` has been set.
# https://www.fastly.com/documentation/guides/concepts/edge-state/cache/stale/
# If it has then do revalidation in the background
    $c->cdn_stale_while_revalidate('1d');

    # And if there is still an error serve from cache
    $c->cdn_stale_if_error('1y');

    $c->res->content_type(
        $feed->isa('XML::FeedPP::Atom')
        ? 'application/atom+xml; charset=UTF-8'
        : 'application/rss+xml; charset=UTF-8'
    );
    $c->res->body( $feed->to_string( indent => 2 ) );
}

__PACKAGE__->meta->make_immutable;

1;
