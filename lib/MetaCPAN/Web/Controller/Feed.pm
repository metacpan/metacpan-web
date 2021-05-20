package MetaCPAN::Web::Controller::Feed;

use Moose;
use namespace::autoclean;

BEGIN { extends 'MetaCPAN::Web::Controller' }

use DateTime::Format::ISO8601 ();
use HTML::Escape qw( escape_html );
use MetaCPAN::Web::Types qw( ArrayRef Enum HashRef Str Undef Uri );
use Params::ValidationCompiler qw( validation_for );
use Path::Tiny qw( path );
use Text::MultiMarkdown qw( markdown );
use XML::FeedPP ();

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

    my %changes_index;

    my @copy = @{ $c->stash->{recent} };
    while ( my @batch = splice( @copy, 0, 100 ) ) {
        my $changes
            = $c->model('API::Changes')
            ->by_releases( [ map { [ $_->{author}, $_->{name} ] } @batch ] )
            ->get;

        for my $x (@$changes) {
            my $k = $x->{author} . '/' . $x->{name};
            $changes_index{$k} = $x;
        }
    }

    for ( @{ $c->stash->{recent} } ) {

        # Provided in Model/API/Changes.pm Line 67
        my $k = $_->{author} . '/' . $_->{name};
        $_->{changes} = $changes_index{$k};
    }

    $c->stash->{feed} = $self->build_feed(
        format  => $type,
        entries => $c->stash->{recent},
        host    => URI->new( $c->config->{web_host} ),
        title   => 'Recent CPAN uploads - MetaCPAN',
    );
}

sub news_rss : Path('/news.rss') Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'news', ['rss'] );
}

sub news_atom : Path('/news.atom') Args(0) {
    my ( $self, $c ) = @_;
    $c->detach( 'news', ['atom'] );
}

sub news : Private {
    my ( $self, $c, $type ) = @_;

    $c->add_surrogate_key('NEWS');
    $c->browser_max_age('1h');
    $c->cdn_max_age('1h');

    my $file = $c->config->{home} . '/News.md';
    my $news = path($file)->slurp_utf8;
    $news =~ s/^\s+|\s+$//g;
    my @entries;
    foreach my $str ( split /^Title:\s*/m, $news ) {
        next if $str =~ /^\s*$/;

        my %e;
        $e{name} = $str =~ s/\A(.+)$//m ? $1 : 'No title';

        # Use the same processing as _Header2Label in
        # Text::MultiMarkdown
        my $a_name = lc $e{name};
        $a_name =~ s/[^A-Za-z0-9:_.-]//g;
        $a_name =~ s/^[^a-z]+//gi;

        $str =~ s/\A\s*-+//g;
        $e{date} = $str =~ s/^Date:\s*(.*)$//m ? $1 : '2014-01-01T00:00:00';
        $e{link}     = '/news';
        $e{fragment} = $a_name;
        $e{author}   = 'METACPAN';
        $str =~ s/^\s*|\s*$//g;

        #$str =~ s{\[([^]]+)\]\(([^)]+)\)}{<a href="$2">$1</a>}g;
        $e{abstract} = $str;
        $e{abstract} = markdown($str);

        push @entries, \%e;
    }

    $c->stash->{feed} = $self->build_feed(
        format  => $type,
        entries => \@entries,
        host    => $c->config->{web_host},
        title   => 'Recent MetaCPAN News',
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
        format  => {
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
            || join( q{/}, 'release', $entry->{author}, $entry->{name} ) );
    $link->fragment( $entry->{fragment} ) if $entry->{fragment};    # for news
    $e->link( $link->as_string );

    $e->author( $entry->{author} );
    $e->pubDate( $entry->{date} );
    $e->title( $entry->{name} );

    my $content = escape_html( $entry->{abstract} // '' );

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

    my $format
        = $params{format} eq 'rdf'  ? 'RDF'
        : $params{format} eq 'rss'  ? 'RSS'
        : $params{format} eq 'atom' ? 'Atom::Atom10'
        :                             die "invalid format";

    my $feed_class = "XML::FeedPP::$format";

    my $feed = $feed_class->new;
    $feed->title( $params{title} );
    $feed->link('/');

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
            = join( q{/}, 'release', $item->{author}, $item->{name} );
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
        $fav->{link}   = join( q{/}, 'release', $fav->{distribution} );
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
    $c->res->content_type(
        $feed->isa('XML::FeedPP::Atom')
        ? 'application/atom+xml; charset=UTF-8'
        : 'application/rss+xml; charset=UTF-8'
    );
    $c->res->body( $feed->to_string( indent => 2 ) );
}

__PACKAGE__->meta->make_immutable;

1;
